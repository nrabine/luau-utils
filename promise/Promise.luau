--!strict

export type Status = "Pending" | "Fulfilled" | "Rejected"
export type Executor<T> = (resolve: Resolve<T>, reject: Reject) -> ()
export type Handler<T, U> = (input: T) -> U | Promise<U>
type Reaction<T> = (input: T) -> ()
type Resolve<T> = (value: T | Promise<T>) -> ()
type Reject = (reason: unknown) -> ()

local Status = table.freeze({
	Pending = "Pending" :: Status,
	Fulfilled = "Fulfilled" :: Status,
	Rejected = "Rejected" :: Status,
})

local Promise = {}
Promise.__index = Promise

export type Promise<T> = typeof(setmetatable(
	{} :: {
		_status: Status,
		_result: unknown,
		_fulfillReactions: { Reaction<T> },
		_rejectReactions: { Reaction<unknown> },
	},
	Promise
))

local function runHandler<T, U>(handler: Handler<T, U>, input: T, resolve: Resolve<U>, reject: Reject)
	local success, result = pcall(handler, input)
	
	if not success then
		reject(result)
	else
		resolve(result :: U)
	end
end

function Promise.new<T>(executor: Executor<T>): Promise<T>
	local self: Promise<T> = setmetatable({
		_status = Status.Pending,
		_result = nil,
		_fulfillReactions = {},
		_rejectReactions = {},
	}, Promise)
	
	local isResolved = false
	
	local function settle<U>(
		status: Status,
		result: U,
		reactions: { Reaction<U> }
	)
		self._status = status
		self._result = result

		for _, reaction in reactions do
			task.spawn(reaction, result)
		end

		table.clear(self._fulfillReactions)
		table.clear(self._rejectReactions)
	end

	local function fulfillPromise(value: T)
		settle(Status.Fulfilled, value, self._fulfillReactions)
	end
	
	local function rejectPromise(reason: unknown)
		settle(Status.Rejected, reason, self._rejectReactions)
	end
	
	local function resolve(value: T | Promise<T>)
		if isResolved then
			return
		end
		
		isResolved = true
		
		if value == self then
			rejectPromise("Promise resolved with self")
		elseif Promise.is(value) then
			(value :: Promise<T>):_subscribe(fulfillPromise, rejectPromise)
		else
			fulfillPromise(value :: T)
		end
	end
	
	local function reject(reason: unknown)
		if isResolved then
			return
		end

		isResolved = true
		
		rejectPromise(reason)
	end

	task.spawn(function()
		local success, result = pcall(executor, resolve, reject)
		
		if not success then
			reject(result)
		end
	end)

	return self
end

function Promise.is(value: unknown): boolean
	return type(value) == "table" and getmetatable(value) == Promise
end

function Promise.next<T, U>(self: Promise<T>, onFulfilled: Handler<T, U>): Promise<U>
	return Promise.new(function(resolve: Resolve<U>, reject)
		self:_subscribe(function(value: T)
			runHandler(onFulfilled, value, resolve, reject)
		end, reject)
	end)
end

function Promise.catch<T, U>(self: Promise<T>, onRejected: Handler<unknown, U>): Promise<T | U>
	return Promise.new(function(resolve: Resolve<T | U>, reject)
		self:_subscribe(resolve, function(reason: unknown)
			runHandler(onRejected, reason, resolve, reject)
		end)
	end)
end

function Promise.await<T>(self: Promise<T>): T
	if self._status == Status.Pending then
		local thread = coroutine.running()

		local function wake()
			task.spawn(thread)
		end

		self:_subscribe(wake, wake)

		coroutine.yield()
	end

	if self._status == Status.Rejected then
		error(self._result, 2)
	end

	return self._result :: T
end

function Promise._subscribe<T>(
	self: Promise<T>,
	fulfillReaction: Reaction<T>,
	rejectReaction: Reaction<unknown>
)
	if self._status == Status.Pending then
		table.insert(self._fulfillReactions, fulfillReaction)
		table.insert(self._rejectReactions, rejectReaction)
	elseif self._status == Status.Fulfilled then
		task.spawn(fulfillReaction, self._result :: T)
	else
		task.spawn(rejectReaction, self._result)
	end
end

return Promise
