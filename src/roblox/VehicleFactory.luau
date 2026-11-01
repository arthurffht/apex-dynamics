--!strict
local Workspace = game:GetService("Workspace")
local Units = require(script.Parent.Parent.Core.Units)
local ReferenceSedan = require(script.Parent.Parent.Presets.ReferenceSedan)
type Config = typeof(ReferenceSedan)
local VehicleFactory = {}

function VehicleFactory.create(
    config: Config?,
    frame: CFrame?,
    name: string?
): (Model, BasePart, VehicleSeat)
    local resolved = config or ReferenceSedan
    local model = Instance.new("Model")
    model.Name = name or "ApexReferenceSedan"
    local chassis = Instance.new("Part")
    chassis.Name = "Chassis"
    chassis.Size = Vector3.new(Units.toStuds(1.7), Units.toStuds(0.45), Units.toStuds(4.1))
    chassis.CFrame = frame or CFrame.new(0, Units.toStuds(1.1), 0)
    chassis.Color = Color3.fromRGB(30, 95, 130)
    local volume = chassis.Size.X * chassis.Size.Y * chassis.Size.Z
    chassis.CustomPhysicalProperties =
        PhysicalProperties.new(Units.toRobloxMass(resolved.massKg) / volume, 0, 0, 100, 100)
    chassis.EnableFluidForces = false
    chassis.Parent = model
    model.PrimaryPart = chassis
    local seat = Instance.new("VehicleSeat")
    seat.Name = "DriverSeat"
    seat.Size = Vector3.new(2, 1, 2)
    seat.CFrame = chassis.CFrame * CFrame.new(0, 1.2, 0)
    seat.Massless = true
    seat.CanCollide = false
    seat.HeadsUpDisplay = false
    seat.MaxSpeed = 0
    seat.Torque = 0
    seat.Parent = model
    local seatWeld = Instance.new("WeldConstraint")
    seatWeld.Part0 = chassis
    seatWeld.Part1 = seat
    seatWeld.Parent = seat
    for _, z in { -0.5, 0.5 } do
        for _, x in { -0.5, 0.5 } do
            local wheel = Instance.new("Part")
            wheel.Name = "WheelVisual"
            wheel.Shape = Enum.PartType.Cylinder
            local diameter = Units.toStuds(resolved.wheelRadiusM * 2)
            wheel.Size = Vector3.new(0.7, diameter, diameter)
            wheel.CFrame = chassis.CFrame
                * CFrame.new(
                    Units.toStuds(resolved.trackM * x),
                    -Units.toStuds(0.44),
                    Units.toStuds(resolved.wheelbaseM * z)
                )
            wheel.Color = Color3.fromRGB(25, 25, 28)
            wheel.Massless = true
            wheel.CanCollide = false
            wheel.CanQuery = false
            wheel.Parent = model
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = chassis
            weld.Part1 = wheel
            weld.Parent = wheel
        end
    end
    model.Parent = Workspace
    chassis:SetNetworkOwner(nil)
    return model, chassis, seat
end

return table.freeze(VehicleFactory)
