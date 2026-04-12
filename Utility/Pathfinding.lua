local DEFAULT_SETTINGS = {
	TIME_VARIANCE = 0.07;
	COMPARISON_CHECKS = 1;
	JUMP_WHEN_STUCK = true;
	STUCK_THRESHOLD = 0.5;
	STUCK_DISTANCE = 0.1;
	MAX_RECOMPUTES = 3;
};

local PathfindingService = game:GetService("PathfindingService");
local Players = game:GetService("Players");
local RunService = game:GetService("RunService");

local function output(func, msg)
	func(((func == error and "SimplePath Error: ") or "SimplePath: ") .. msg);
end

local Path = {
	StatusType = {
		Idle = "Idle";
		Active = "Active";
	};
	ErrorType = {
		LimitReached = "LimitReached";
		TargetUnreachable = "TargetUnreachable";
		ComputationError = "ComputationError";
		AgentStuck = "AgentStuck";
		AgentDied = "AgentDied";
	};
};

Path.__index = function(self, index)
	if index == "Stopped" and not self._humanoid then
		output(error, "Attempt to use Path.Stopped on a non-humanoid.");
	end;

	return (self._events[index] and self._events[index].Event)
		or (index == "LastError" and self._lastError)
		or (index == "Status" and self._status)
		or Path[index];
end;

local visualWaypoint = Instance.new("Part");
visualWaypoint.Size = Vector3.new(0.5, 0.5, 0.5);
visualWaypoint.Anchored = true;
visualWaypoint.CanCollide = false;
visualWaypoint.Material = Enum.Material.Neon;
visualWaypoint.Shape = Enum.PartType.Block;
visualWaypoint.Name = "SimplePathWaypoint";

local function declareError(self, errorType)
	self._lastError = errorType;
	if self._events and self._events.Error then
		self._events.Error:Fire(errorType);
	end;
end

local function destroyVisualWaypoints(waypoints)
	if waypoints then
		for _, waypoint in ipairs(waypoints) do
			if waypoint then
				waypoint:Destroy();
			end;
		end;
	end;
	return nil;
end

local function isAgentAlive(self)
	if not self._agent or not self._agent.Parent then
		return false;
	end;

	if not self._agent.PrimaryPart then
		return false;
	end;

	if self._humanoid then
		return self._humanoid.Parent ~= nil and self._humanoid.Health > 0;
	end;

	return true;
end

local function getTargetPosition(target)
	return typeof(target) == "Vector3" and target or target.Position;
end

local function disconnectMoveConnection(self)
	if self._moveConnection then
		self._moveConnection:Disconnect();
		self._moveConnection = nil;
	end;
end

local function disconnectStuckConnection(self)
	if self._stuckDetectConnection then
		self._stuckDetectConnection:Disconnect();
		self._stuckDetectConnection = nil;
	end;
end

local function disconnectDiedConnection(self)
	if self._diedConnection then
		self._diedConnection:Disconnect();
		self._diedConnection = nil;
	end;
end

local function hardStopHumanoid(self)
	if self._humanoid and self._humanoid.Parent and self._agent and self._agent.PrimaryPart then
		pcall(function()
			self._humanoid:MoveTo(self._agent.PrimaryPart.Position);
		end);
	end;
end

local function cleanupRun(self, fireStopped)
	disconnectMoveConnection(self);
	disconnectStuckConnection(self);

	self._status = Path.StatusType.Idle;
	self._target = nil;
	self._waypoints = nil;
	self._currentWaypoint = nil;
	self._visualWaypoints = destroyVisualWaypoints(self._visualWaypoints);

	if fireStopped and self._events and self._events.Stopped then
		self._events.Stopped:Fire(self._agent);
	end;
end

local function createVisualWaypoints(waypoints)
	local visualWaypoints = {};

	if #waypoints > 0 then
		local startV = visualWaypoint:Clone();
		startV.Position = waypoints[1].Position;
		startV.Color = Color3.fromRGB(255, 255, 0);
		startV.Parent = workspace;
		table.insert(visualWaypoints, startV);
	end;

	for i = 1, #waypoints - 1 do
		local startPos = waypoints[i].Position;
		local goalPos = waypoints[i + 1].Position;
		local dir = goalPos - startPos;
		local dist = dir.Magnitude;
		local stepSize = 5;
		local steps = math.max(1, math.floor(dist / stepSize));

		for j = 0, steps do
			local alpha = j / steps;
			local pos = startPos:Lerp(goalPos, alpha);

			local v = visualWaypoint:Clone();
			v.Position = pos;
			v.Color = (i + 1 == #waypoints and Color3.fromRGB(0, 255, 0))
				or (waypoints[i + 1].Action == Enum.PathWaypointAction.Jump and Color3.fromRGB(255, 0, 0))
				or Color3.fromRGB(255, 139, 0);
			v.Parent = workspace;
			table.insert(visualWaypoints, v);
		end;
	end;

	return visualWaypoints;
end

local function getNonHumanoidWaypoint(self)
	for i = 2, #self._waypoints do
		if (self._waypoints[i].Position - self._waypoints[i - 1].Position).Magnitude > 0.1 then
			return i;
		end;
	end;
	return 2;
end

local function setJumpState(self)
	if not self._humanoid or self._humanoid.Health <= 0 then
		return;
	end;

	pcall(function()
		local state = self._humanoid:GetState();
		if state ~= Enum.HumanoidStateType.Jumping and state ~= Enum.HumanoidStateType.Freefall then
			self._humanoid:ChangeState(Enum.HumanoidStateType.Jumping);
		end;
	end);
end

local function invokeWaypointReached(self)
	local lastWaypoint = self._waypoints[self._currentWaypoint - 1];
	local nextWaypoint = self._waypoints[self._currentWaypoint];
	self._events.WaypointReached:Fire(self._agent, lastWaypoint, nextWaypoint);
end

local function move(self)
	if not isAgentAlive(self) then
		cleanupRun(self, false);
		declareError(self, self.ErrorType.AgentDied);
		return;
	end;

	local waypoint = self._waypoints and self._waypoints[self._currentWaypoint];
	if not waypoint then
		return;
	end;

	if waypoint.Action == Enum.PathWaypointAction.Jump then
		setJumpState(self);
	end;

	self._humanoid:MoveTo(waypoint.Position);
end

local function moveToFinished(self, reached)
	if not getmetatable(self) then
		return;
	end;

	if not isAgentAlive(self) then
		cleanupRun(self, false);
		declareError(self, self.ErrorType.AgentDied);
		return;
	end;

	if not self._humanoid then
		if reached and self._currentWaypoint + 1 <= #self._waypoints then
			invokeWaypointReached(self);
			self._currentWaypoint += 1;
		elseif reached then
			self._visualWaypoints = destroyVisualWaypoints(self._visualWaypoints);
			self._target = nil;
			self._events.Reached:Fire(self._agent, self._waypoints[self._currentWaypoint]);
		else
			self._visualWaypoints = destroyVisualWaypoints(self._visualWaypoints);
			self._target = nil;
			declareError(self, self.ErrorType.TargetUnreachable);
		end;
		return;
	end;

	if reached and self._currentWaypoint + 1 <= #self._waypoints then
		if self._currentWaypoint + 1 < #self._waypoints then
			invokeWaypointReached(self);
		end;
		self._currentWaypoint += 1;
		move(self);
	elseif reached then
		local reachedWaypoint = self._waypoints[self._currentWaypoint];
		cleanupRun(self, false);
		self._events.Reached:Fire(self._agent, reachedWaypoint);
	else
		cleanupRun(self, false);
		declareError(self, self.ErrorType.TargetUnreachable);
	end;
end

local function checkForStuck(self)
	if not self._humanoid or self._status ~= Path.StatusType.Active then
		return;
	end;

	if not isAgentAlive(self) then
		cleanupRun(self, false);
		declareError(self, self.ErrorType.AgentDied);
		return;
	end;

	local currentTime = os.clock();
	local dt = currentTime - self._lastTime;
	self._lastTime = currentTime;

	local currentPos = self._agent.PrimaryPart.Position;
	local dist = (currentPos - self._position._last).Magnitude;
	self._position._last = currentPos;

	if dist < self._settings.STUCK_DISTANCE then
		self._stuckTime += dt;
	else
		self._stuckTime = 0;
	end;

	if self._stuckTime > self._settings.STUCK_THRESHOLD then
		self._stuckTime = 0;

		if self._settings.JUMP_WHEN_STUCK then
			setJumpState(self);
		end;

		self._recomputeCount += 1;

		if self._recomputeCount > self._settings.MAX_RECOMPUTES then
			cleanupRun(self, false);
			declareError(self, self.ErrorType.AgentStuck);
		else
			local target = self._target;
			if target then
				self:Run(target, true);
			end;
		end;
	end;
end

function Path.GetNearestCharacter(fromPosition)
	local character, dist = nil, math.huge;

	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character;
		if char and char.PrimaryPart then
			local newDist = (char.PrimaryPart.Position - fromPosition).Magnitude;
			if newDist < dist then
				character = char;
				dist = newDist;
			end;
		end;
	end;

	return character;
end

function Path.new(agent, agentParameters, override)
	if not (agent and agent:IsA("Model") and agent.PrimaryPart) then
		output(error, "Pathfinding agent must be a valid Model Instance with a set PrimaryPart.");
	end;

	local self = setmetatable({
		_settings = override or {};
		_events = {
			Reached = Instance.new("BindableEvent");
			WaypointReached = Instance.new("BindableEvent");
			Blocked = Instance.new("BindableEvent");
			Error = Instance.new("BindableEvent");
			Stopped = Instance.new("BindableEvent");
		};
		_agent = agent;
		_humanoid = agent:FindFirstChildOfClass("Humanoid");
		_path = PathfindingService:CreatePath(agentParameters);
		_status = Path.StatusType.Idle;
		_t = 0;
		_target = nil;
		_waypoints = nil;
		_currentWaypoint = nil;
		_position = {
			_last = Vector3.new();
			_count = 0;
		};
		_stuckTime = 0;
		_recomputeCount = 0;
		_lastTime = os.clock();
	}, Path);

	for setting, value in pairs(DEFAULT_SETTINGS) do
		if self._settings[setting] == nil then
			self._settings[setting] = value;
		end;
	end;

	self._path.Blocked:Connect(function(blockedWaypointIndex)
		if not self._humanoid or self._status ~= Path.StatusType.Active then
			return;
		end;

		if self._currentWaypoint and blockedWaypointIndex >= self._currentWaypoint then
			setJumpState(self);
			if self._waypoints and self._waypoints[blockedWaypointIndex] then
				self._events.Blocked:Fire(self._agent, self._waypoints[blockedWaypointIndex]);
			end;
		end;
	end);

	if self._humanoid then
		self._diedConnection = self._humanoid.Died:Connect(function()
			cleanupRun(self, false);
			declareError(self, self.ErrorType.AgentDied);
		end);
	end;

	return self;
end

function Path:Destroy()
	if self._events then
		for _, event in pairs(self._events) do
			event:Destroy();
		end;
	end;

	self._events = nil;
	self._visualWaypoints = destroyVisualWaypoints(self._visualWaypoints);

	disconnectDiedConnection(self);
	disconnectStuckConnection(self);
	disconnectMoveConnection(self);

	if self._path then
		self._path:Destroy();
	end;

	setmetatable(self, nil);

	for k in pairs(self) do
		self[k] = nil;
	end;
end

function Path:Stop()
	if not self._humanoid then
		output(error, "Attempt to call Path:Stop() on a non-humanoid.");
		return;
	end;

	if self._status == Path.StatusType.Idle then
		return false;
	end;

	hardStopHumanoid(self);
	cleanupRun(self, true);
	return true;
end

function Path:GetPath(target)
	if not (target and (typeof(target) == "Vector3" or target:IsA("BasePart"))) then
		output(error, "Pathfinding target must be a valid Vector3 or BasePart.");
		return nil;
	end;

	if not isAgentAlive(self) then
		declareError(self, self.ErrorType.AgentDied);
		return nil;
	end;

	local ok = pcall(function()
		self._path:ComputeAsync(self._agent.PrimaryPart.Position, getTargetPosition(target));
	end);

	if not ok or self._path.Status == Enum.PathStatus.NoPath or #self._path:GetWaypoints() < 2 then
		return nil;
	end;

	local waypoints = self._path:GetWaypoints();

	if self.Visualize then
		self._visualWaypoints = destroyVisualWaypoints(self._visualWaypoints);
		self._visualWaypoints = createVisualWaypoints(waypoints);
	end;

	return waypoints;
end

function Path:Run(target, bypassRateLimit)
	if not target and not self._humanoid and self._target then
		moveToFinished(self, true);
		return true;
	end;

	if not (target and (typeof(target) == "Vector3" or target:IsA("BasePart"))) then
		output(error, "Pathfinding target must be a valid Vector3 or BasePart.");
		return false;
	end;

	if not isAgentAlive(self) then
		declareError(self, self.ErrorType.AgentDied);
		return false;
	end;

	if self._status == Path.StatusType.Active then
		hardStopHumanoid(self);
		cleanupRun(self, false);
	end;

	if self._humanoid and not bypassRateLimit then
		if os.clock() - self._t <= self._settings.TIME_VARIANCE then
			declareError(self, self.ErrorType.LimitReached);
			return false;
		end;
		self._t = os.clock();
	end;

	local ok = pcall(function()
		self._path:ComputeAsync(self._agent.PrimaryPart.Position, getTargetPosition(target));
	end);

	if not ok
		or self._path.Status == Enum.PathStatus.NoPath
		or #self._path:GetWaypoints() < 2
		or (self._humanoid and self._humanoid:GetState() == Enum.HumanoidStateType.Freefall) then
		self._visualWaypoints = destroyVisualWaypoints(self._visualWaypoints);
		declareError(self, self.ErrorType.ComputationError);
		return false;
	end;

	self._status = self._humanoid and Path.StatusType.Active or Path.StatusType.Idle;
	self._target = target;

	pcall(function()
		self._agent.PrimaryPart:SetNetworkOwner(nil);
	end);

	self._waypoints = self._path:GetWaypoints();
	self._currentWaypoint = 2;

	self._position._last = self._agent.PrimaryPart.Position;
	self._stuckTime = 0;
	self._recomputeCount = 0;
	self._lastTime = os.clock();

	self._visualWaypoints = destroyVisualWaypoints(self._visualWaypoints);
	self._visualWaypoints = self.Visualize and createVisualWaypoints(self._waypoints) or nil;

	disconnectMoveConnection(self);
	disconnectStuckConnection(self);

	if self._humanoid then
		self._moveConnection = self._humanoid.MoveToFinished:Connect(function(reached)
			moveToFinished(self, reached);
		end);

		self._stuckDetectConnection = RunService.Heartbeat:Connect(function()
			checkForStuck(self);
		end);
	end;

	if self._humanoid then
		move(self);
	elseif #self._waypoints == 2 then
		local reachedWaypoint = self._waypoints[2];
		self._target = nil;
		self._visualWaypoints = destroyVisualWaypoints(self._visualWaypoints);
		self._events.Reached:Fire(self._agent, reachedWaypoint);
	else
		self._currentWaypoint = getNonHumanoidWaypoint(self);
		moveToFinished(self, true);
	end;

	return true;
end

return Path;
