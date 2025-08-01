--!strict
--!native
local Cuboid = {} :: CuboidImplementation
Cuboid.__index = Cuboid

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")

local CONSTANTS = require(Modules:WaitForChild("Constants"))

local EPSILON = CONSTANTS.ArithmeticOperations.EPSILON

local Classes = Modules:WaitForChild("Classes")
local OrthogonalCuboid = require(Classes:WaitForChild("OrthogonalCuboid"))

local Libraries = Modules:WaitForChild("Libraries")
local Table = require(Libraries:WaitForChild("Table"))

type CuboidImplementation = {
	__index: CuboidImplementation,
	__tostring: (self: Cuboid) -> string,
	__eq: (self: Cuboid, value: any) -> boolean,
	__add: (self: Cuboid, value: Cuboid | Vector3) -> Cuboid,
	__sub: (self: Cuboid, value: Cuboid | Vector3) -> Cuboid,
	__mul: (self: Cuboid, value: Cuboid | CFrame) -> Cuboid,
	__div: (self: Cuboid, value: Cuboid | CFrame) -> Cuboid,
	IsCuboid: (value: any) -> boolean,
	new: (cframe: CFrame?, size: Vector3?) -> Cuboid,
	FromCFrame: (cframe: CFrame) -> Cuboid,
	FromSize: (size: Vector3) -> Cuboid,
	GetNormals: (self: Cuboid) -> {Vector3},
	GetVertices: (self: Cuboid) -> {Vector3},
	IsPointIntersecting: (self: Cuboid, point: Vector3, epsilon: number?) -> boolean,
	IsCuboidIntersecting: (self: Cuboid, cuboid: Cuboid, epsilon: number?) -> boolean,
	IsCuboidEnclosed: (self: Cuboid, cuboid: Cuboid, epsilon: number?) -> boolean,
	ToAxisAlignedBoundingBox: (self: Cuboid) -> OrthogonalCuboid.OrthogonalCuboid,
	ResolveIntersection: (self: Cuboid, static: Cuboid) -> Cuboid,
	SnapToIncrement: (self: Cuboid, increment: number) -> Cuboid
}

type CuboidProperties = {
	CFrame: CFrame,
	Size: Vector3
}

export type Cuboid = typeof(
	setmetatable(
		{} :: CuboidProperties,
		{} :: CuboidImplementation
	)
)

--[=[
	Returns the minimum and maximum scalar dot products of each <strong>Vector3</strong> in <code>Points</code> onto <code>Vector</code>.
]=]
local function GetScalarDotProductExtents(points: {Vector3}, vector: Vector3): (number, number)
	local products = table.create(#points)

	for _, point in points do
		table.insert(products, point:Dot(vector))
	end

	return math.min(unpack(products)), math.max(unpack(products))
end

function Cuboid:__tostring(): string
	return `{self.CFrame}, {self.Size}`
end

function Cuboid:__eq(value: any): boolean
	return Cuboid.IsCuboid(value) and self.CFrame == value.CFrame and self.Size == value.Size
end

function Cuboid:__add(value: Cuboid | Vector3): Cuboid
	local isCuboid = Cuboid.IsCuboid(value)

	assert(isCuboid or type(value) == "vector", `Argument 'Value' to metamethod '__add' of Cuboid on {self} is {value} and not a Cuboid or Vector3.`)

	if isCuboid then
		return Cuboid.new(self.CFrame + (value :: any).CFrame.Position, self.Size + (value :: any).Size)
	else
		return Cuboid.new(self.CFrame + value, self.Size)
	end
end

function Cuboid:__sub(value: Cuboid | Vector3): Cuboid
	local isCuboid = Cuboid.IsCuboid(value)

	assert(isCuboid or type(value) == "vector", `Argument 'Value' to metamethod '__sub' of Cuboid on {self} is {value} and not a Cuboid or Vector3.`)

	if isCuboid then
		return Cuboid.new(self.CFrame - (value :: any).CFrame.Position, self.Size - (value :: any).Size)
	else
		return Cuboid.new(self.CFrame - value, self.Size)
	end
end

function Cuboid:__mul(value: Cuboid | CFrame): Cuboid
	local isCuboid = Cuboid.IsCuboid(value)

	assert(isCuboid or typeof(value) == "CFrame", `Argument 'Value' to metamethod '__mul' of Cuboid on {self} is {value} and not a Cuboid or CFrame.`)

	if isCuboid then
		return Cuboid.new(self.CFrame * (value :: any).CFrame, self.Size * (value :: any).Size)
	else
		return Cuboid.new(self.CFrame * value, self.Size)
	end
end

function Cuboid:__div(value: Cuboid | CFrame): Cuboid
	local isCuboid = Cuboid.IsCuboid(value)

	assert(isCuboid or typeof(value) == "CFrame", `Argument 'Value' to metamethod '__div' of Cuboid on {self} is {value} and not a Cuboid or CFrame.`)

	if isCuboid then
		return Cuboid.new(self.CFrame * (value :: any).CFrame:Inverse(), self.Size / (value :: any).Size)
	else
		return Cuboid.new(self.CFrame * value:Inverse(), self.Size)
	end
end

function Cuboid.IsCuboid(value: any): boolean
	return type(value) == "table" and getmetatable(value) == Cuboid
end

--[=[
	Returns a new <strong>Cuboid</strong> with <code>CFrame</code> and <code>Size</code>.
]=]
local function Construct(cframe: CFrame, size: Vector3): Cuboid
	return setmetatable({
		CFrame = cframe,
		Size = size
	}, Cuboid)
end

function Cuboid.new(cframe: CFrame?, size: Vector3?): Cuboid
	assert(cframe == nil or typeof(cframe) == "CFrame", `Argument 'CFrame' to constructor 'new' of Cuboid is {cframe} and not a CFrame or nil.`)
	assert(size == nil or type(size) == "vector", `Argument 'Size' to constructor 'new' of Cuboid is {size} and not a Vector3 or nil.`)

	return Construct(cframe or CFrame.new(), size or Vector3.zero)
end

function Cuboid.FromCFrame(cframe: CFrame): Cuboid
	assert(typeof(cframe) == "CFrame", `Argument 'CFrame' to constructor 'FromCFrame' of Cuboid is {cframe} and not a CFrame.`)

	return Construct(cframe, Vector3.zero)
end

function Cuboid.FromSize(size: Vector3): Cuboid
	assert(type(size) == "vector", `Argument 'Size' to constructor 'FromSize' of Cuboid is {size} and not a Vector3.`)

	return Construct(CFrame.new(), size)
end

function Cuboid:GetNormals(): {Vector3}
	local cframe = self.CFrame

	return {
		cframe.XVector, cframe.YVector, cframe.ZVector,
		-cframe.XVector, -cframe.YVector, -cframe.ZVector
	}
end

function Cuboid:GetVertices(): {Vector3}
	local cframe, halfSize = self.CFrame, self.Size / 2

	return {
		cframe * halfSize,
		cframe * Vector3.new(halfSize.X, halfSize.Y, -halfSize.Z),
		cframe * Vector3.new(halfSize.X, -halfSize.Y, halfSize.Z),
		cframe * Vector3.new(halfSize.X, -halfSize.Y, -halfSize.Z),
		cframe * Vector3.new(-halfSize.X, halfSize.Y, halfSize.Z),
		cframe * Vector3.new(-halfSize.X, halfSize.Y, -halfSize.Z),
		cframe * Vector3.new(-halfSize.X, -halfSize.Y, halfSize.Z),
		cframe * -halfSize
	}
end

function Cuboid:IsPointIntersecting(point: Vector3, epsilon: number?): boolean
	epsilon = epsilon or EPSILON

	local cframe = self.CFrame
	local vertices = Cuboid.new(cframe, self.Size + Vector3.one * (epsilon :: any * 2)):GetVertices()

	for _, vector in {cframe.XVector, cframe.YVector, cframe.ZVector} do
		local min, max = GetScalarDotProductExtents(vertices, vector)
		local product = point:Dot(vector)

		if product < min or product > max then
			return false
		end
	end

	return true
end

function Cuboid:IsCuboidIntersecting(cuboid: Cuboid, epsilon: number?): boolean
	epsilon = epsilon or EPSILON

	local vertices1, vertices2 = Cuboid.new(self.CFrame, self.Size - Vector3.one * (epsilon :: any * 2)):GetVertices(), cuboid:GetVertices()

	for _, normal in Table.ConcatenateArrays(self:GetNormals(), cuboid:GetNormals()) do
		local min1, max1 = GetScalarDotProductExtents(vertices1, normal)
		local min2, max2 = GetScalarDotProductExtents(vertices2, normal)

		if min1 > max2 or max1 < min2 then
			return false
		end
	end

	return true
end

function Cuboid:IsCuboidEnclosed(cuboid: Cuboid, epsilon: number?): boolean
	epsilon = epsilon or EPSILON

	local vertices1, vertices2 = self:GetVertices(), Cuboid.new(cuboid.CFrame, cuboid.Size + Vector3.one * (epsilon :: any * 2)):GetVertices()

	for _, normal in Table.ConcatenateArrays(self:GetNormals(), cuboid:GetNormals()) do
		local min1, max1 = GetScalarDotProductExtents(vertices1, normal)
		local min2, max2 = GetScalarDotProductExtents(vertices2, normal)

		if min1 < min2 or max1 > max2 then
			return false
		end
	end

	return true
end

local AxisEnums = Enum.Axis:GetEnumItems()

function Cuboid:ToAxisAlignedBoundingBox(): OrthogonalCuboid.OrthogonalCuboid
	local vertices = self:GetVertices()
	local minComponents: {number}, maxComponents: {number} = table.create(3), table.create(3)

	for index, axis in AxisEnums do
		minComponents[index], maxComponents[index] = GetScalarDotProductExtents(vertices, Vector3.FromAxis(axis))
	end

	local min, max = Vector3.new(unpack(minComponents)), Vector3.new(unpack(maxComponents))

	return OrthogonalCuboid.new((max + min) / 2, max - min)
end

function Cuboid:ResolveIntersection(static: Cuboid): Cuboid
	local dynamicVertices, staticVertices = self:GetVertices(), static:GetVertices()
	local translation, minDelta = Vector3.zero, math.huge

	for _, normal in Table.ConcatenateArrays(self:GetNormals(), static:GetNormals()) do
		local dynamicMin, dynamicMax = GetScalarDotProductExtents(dynamicVertices, normal)
		local staticMin, staticMax = GetScalarDotProductExtents(staticVertices, normal)

		if dynamicMin > staticMax or dynamicMax < staticMin then
			return self
		end

		local delta = staticMax - dynamicMin
		local scaledDelta = delta / (dynamicMax - dynamicMin)

		if scaledDelta < minDelta then
			translation, minDelta = normal * delta, scaledDelta
		end
	end

	return self + Cuboid.FromCFrame(CFrame.new(translation))
end

local AxisNames: {string} = table.create(3)

for _, axis in AxisEnums do
	table.insert(AxisNames, axis.Name)
end

function Cuboid:SnapToIncrement(increment: number): Cuboid
	local aabb = self:ToAxisAlignedBoundingBox()
	local position, size = aabb.Position, aabb.Size

	local components: {number} = table.create(3)

	for _, name in AxisNames do
		local coordinate = (position :: any)[name]
		local component: number

		if math.round((size :: any)[name] * increment) % 2 == 0 then
			component = math.round(coordinate / increment) * increment
		else
			component = coordinate // increment * increment + increment / 2
		end

		table.insert(components, component)
	end

	return Cuboid.new(self.CFrame.Rotation + Vector3.new(unpack(components)), self.Size)
end

return Cuboid
