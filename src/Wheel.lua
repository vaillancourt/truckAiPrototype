local Common = require("Common")

-- This is based on 
-- * http://www.iforce2d.net/b2dtut/top-down-car
-- * http://www.iforce2d.net/src/iforce2d_TopdownCar.h

local Wheel = {
    x = 50,
    y = 50,
    max_forward_speed = Common.kmh_to_mps(20),
    max_backward_speed = Common.kmh_to_mps(12),
    max_drive_force = 1,
    max_lateral_impulse = 0.1,
    max_torque = 15,
    body = nil,
    fixture = nil,
    width = 0.75, -- Assuming the truck is facing "right"/x+
    height = 0.25, }
Wheel.__index = Wheel

function Wheel.new(world, x, y)
    local self = setmetatable({}, Wheel)

    self.x = x or self.x
    self.y = y or self.y

    self.body = love.physics.newBody( world, x, y, "dynamic" )

    local shape = love.physics.newRectangleShape( self.width, self.height )
    local density = 10
    self.fixture = love.physics.newFixture( self.body, shape, density )

    self.body:setUserData( self )

    return self
end


function Wheel.get_lateral_velocity(self)
--     b2Vec2 getLateralVelocity() {
--         b2Vec2 currentRightNormal = m_body->GetWorldVector( b2Vec2(1,0) );
--         return b2Dot( currentRightNormal, m_body->GetLinearVelocity() ) * currentRightNormal;
--     }

    local local_side_x, local_side_y = self.body:getWorldVector( 0, 1 )
    local lin_vel_x, lin_vel_y = self.body:getLinearVelocity( )
    local dot = Common.dot_product(local_side_x, local_side_y, lin_vel_x, lin_vel_y)
    return dot * local_side_x, dot * local_side_y
end


function Wheel.get_forward_velocity(self)
--     b2Vec2 getForwardVelocity() {
--         b2Vec2 currentForwardNormal = m_body->GetWorldVector( b2Vec2(0,1) );
--         return b2Dot( currentForwardNormal, m_body->GetLinearVelocity() ) * currentForwardNormal;
--     }
    local local_forward_x, local_forward_y = self.body:getWorldVector( 1, 0 )
    local lin_vel_x, lin_vel_y = self.body:getLinearVelocity( )
    local dot = Common.dot_product(local_forward_x, local_forward_y, lin_vel_x, lin_vel_y)
    return dot * local_forward_x, dot * local_forward_y
end


function Wheel.update_friction(self)

    do
        --    //lateral linear velocity
        local impulse_x, impulse_y = self:get_lateral_velocity()
        impulse_x = impulse_x * -self.body:getMass()
        impulse_y = impulse_y * -self.body:getMass()
        local impulse_length = Common.vector_length(impulse_x, impulse_y)
        if impulse_length > self.max_lateral_impulse then
            impulse_x = impulse_x * self.max_lateral_impulse / impulse_length
            impulse_y = impulse_y * self.max_lateral_impulse / impulse_length
        end

        self.body:applyLinearImpulse( impulse_x, impulse_y )
    end

    do
        --    //angular velocity
        local inertia = self.body:getInertia()
        local ang_vel = self.body:getAngularVelocity()
        self.body:applyAngularImpulse( 0.1 * inertia * -ang_vel)
    end

    do
        --    //forward linear velocity
        -- local forward_vel_x, forward_vel_y = self:get_forward_velocity()
        local forward_dir_x, forward_dir_y, speed = Common.vector_normalize(self:get_forward_velocity())
        if speed > 0 or speed < 0 then
            Common.vector_print(forward_dir_x, forward_dir_y, "forward_dir")
            local drag_force_magnitude = -2 * speed
            print("speed " .. speed)
            --print("speed " .. speed)
            self.body:applyForce(drag_force_magnitude * forward_dir_x, drag_force_magnitude * forward_dir_y)
        end
    end


    --void updateFriction() {
    --    //lateral linear velocity
    --    b2Vec2 impulse = m_body->GetMass() * -getLateralVelocity();
    --    if ( impulse.Length() > m_maxLateralImpulse )
    --        impulse *= m_maxLateralImpulse / impulse.Length();
    --    m_body->ApplyLinearImpulse( m_currentTraction * impulse, m_body->GetWorldCenter() );

    --    //angular velocity
    --    m_body->ApplyAngularImpulse( m_currentTraction * 0.1f * m_body->GetInertia() * -m_body->GetAngularVelocity() );

    --    //forward linear velocity
    --    b2Vec2 currentForwardNormal = getForwardVelocity();
    --    float currentForwardSpeed = currentForwardNormal.Normalize();
    --    float dragForceMagnitude = -2 * currentForwardSpeed;
    --    m_body->ApplyForce( m_currentTraction * dragForceMagnitude * currentForwardNormal, m_body->GetWorldCenter() );
    --}
end

--- Updates the driving of the wheel
-- 
-- @param control value in the range [-1..1]
function Wheel.update_drive(self, dt, control)
    local desired_speed = 0
    if control > 0 then
        desired_speed = control * self.max_forward_speed * dt
    elseif control < 0 then
        desired_speed = control * self.max_backward_speed * dt
    end 

    local local_forward_x, local_forward_y = self.body:getWorldVector( 1, 0 )
    local forward_vel_x, forward_vel_y = self:get_forward_velocity()
    local current_speed = Common.dot_product(local_forward_x, local_forward_y, forward_vel_x, forward_vel_y)

    if desired_speed > current_speed then
        self.body:applyForce( local_forward_x * self.max_drive_force, local_forward_y * self.max_drive_force)
        --print(local_forward_x * self.max_drive_force .. " " .. local_forward_y * self.max_drive_force)
        --m_body->ApplyForce( m_currentTraction * force * currentForwardNormal, m_body->GetWorldCenter() );
        print("forward")
    elseif desired_speed < current_speed then
        self.body:applyForce( local_forward_x * -self.max_drive_force, local_forward_y * -self.max_drive_force)
        print("rev")
    else
        print("nothing")
        -- do nothing
    end
    do 
        local x, y = self.body:getPosition()
        Common.vector_print(x, y, "WheelPosition")
    end
--     void updateDrive(int controlState) {
-- 
--         //find desired speed
--         float desiredSpeed = 0;
--         switch ( controlState & (TDC_UP|TDC_DOWN) ) {
--             case TDC_UP:   desiredSpeed = m_maxForwardSpeed;  break;
--             case TDC_DOWN: desiredSpeed = m_maxBackwardSpeed; break;
--             default: return;//do nothing
--         }
-- 
--         //find current speed in forward direction
--         b2Vec2 currentForwardNormal = m_body->GetWorldVector( b2Vec2(0,1) );
--         float currentSpeed = b2Dot( getForwardVelocity(), currentForwardNormal );
-- 
--         //apply necessary force
--         float force = 0;
--         if ( desiredSpeed > currentSpeed )
--             force = m_maxDriveForce;
--         else if ( desiredSpeed < currentSpeed )
--             force = -m_maxDriveForce;
--         else
--             return;
--         m_body->ApplyForce( m_currentTraction * force * currentForwardNormal, m_body->GetWorldCenter() );
--     }
end


--- Updates the turning (steering) of the wheel
-- 
-- @param control value in the range [-1..1] where values below 0 mean "turn right" and values above zero mean "turn 
--        left".
function Wheel.update_turn(self, dt, control)
    local desired_torque = (control or 0) * self.max_torque
    self.body:applyTorque(desired_torque)
--     void updateTurn(int controlState) {
--         float desiredTorque = 0;
--         switch ( controlState & (TDC_LEFT|TDC_RIGHT) ) {
--             case TDC_LEFT:  desiredTorque = 15;  break;
--             case TDC_RIGHT: desiredTorque = -15; break;
--             default: ;//nothing
--         }
--         m_body->ApplyTorque( desiredTorque );
--     }
end

function Wheel.draw(self)
    local colour = {1.0, 1.0, 1.0, 1.0}
    local radius = 5
    love.graphics.setColor(colour)
    love.graphics.circle("fill", self.x, self.y, radius)
end


-- class TDTire {
-- public:
--     b2Body* m_body;
--     float m_maxForwardSpeed;
--     float m_maxBackwardSpeed;
--     float m_maxDriveForce;
--     float m_maxLateralImpulse;
--     std::set<GroundAreaFUD*> m_groundAreas;
--     float m_currentTraction;
-- 
--     TDTire(b2World* world) {
--         b2BodyDef bodyDef;
--         bodyDef.type = b2_dynamicBody;
--         m_body = world->CreateBody(&bodyDef);
-- 
--         b2PolygonShape polygonShape;
--         polygonShape.SetAsBox( 0.5f, 1.25f );
--         b2Fixture* fixture = m_body->CreateFixture(&polygonShape, 1);//shape, density
--         fixture->SetUserData( new CarTireFUD() );
-- 
--         m_body->SetUserData( this );
-- 
--         m_currentTraction = 1;
--     }
-- 
--     ~TDTire() {
--         m_body->GetWorld()->DestroyBody(m_body);
--     }
-- 
--     void setCharacteristics(float maxForwardSpeed, float maxBackwardSpeed, float maxDriveForce, float maxLateralImpulse) {
--         m_maxForwardSpeed = maxForwardSpeed;
--         m_maxBackwardSpeed = maxBackwardSpeed;
--         m_maxDriveForce = maxDriveForce;
--         m_maxLateralImpulse = maxLateralImpulse;
--     }
-- 
--     void addGroundArea(GroundAreaFUD* ga) { m_groundAreas.insert(ga); updateTraction(); }
--     void removeGroundArea(GroundAreaFUD* ga) { m_groundAreas.erase(ga); updateTraction(); }
-- 
--     void updateTraction()
--     {
--         if ( m_groundAreas.empty() )
--             m_currentTraction = 1;
--         else {
--             //find area with highest traction
--             m_currentTraction = 0;
--             std::set<GroundAreaFUD*>::iterator it = m_groundAreas.begin();
--             while (it != m_groundAreas.end()) {
--                 GroundAreaFUD* ga = *it;
--                 if ( ga->frictionModifier > m_currentTraction )
--                     m_currentTraction = ga->frictionModifier;
--                 ++it;
--             }
--         }
--     }
-- 
--     b2Vec2 getLateralVelocity() {
--         b2Vec2 currentRightNormal = m_body->GetWorldVector( b2Vec2(1,0) );
--         return b2Dot( currentRightNormal, m_body->GetLinearVelocity() ) * currentRightNormal;
--     }
-- 
--     b2Vec2 getForwardVelocity() {
--         b2Vec2 currentForwardNormal = m_body->GetWorldVector( b2Vec2(0,1) );
--         return b2Dot( currentForwardNormal, m_body->GetLinearVelocity() ) * currentForwardNormal;
--     }
-- 
--     void updateFriction() {
--         //lateral linear velocity
--         b2Vec2 impulse = m_body->GetMass() * -getLateralVelocity();
--         if ( impulse.Length() > m_maxLateralImpulse )
--             impulse *= m_maxLateralImpulse / impulse.Length();
--         m_body->ApplyLinearImpulse( m_currentTraction * impulse, m_body->GetWorldCenter() );
-- 
--         //angular velocity
--         m_body->ApplyAngularImpulse( m_currentTraction * 0.1f * m_body->GetInertia() * -m_body->GetAngularVelocity() );
-- 
--         //forward linear velocity
--         b2Vec2 currentForwardNormal = getForwardVelocity();
--         float currentForwardSpeed = currentForwardNormal.Normalize();
--         float dragForceMagnitude = -2 * currentForwardSpeed;
--         m_body->ApplyForce( m_currentTraction * dragForceMagnitude * currentForwardNormal, m_body->GetWorldCenter() );
--     }
-- 
--     void updateDrive(int controlState) {
-- 
--         //find desired speed
--         float desiredSpeed = 0;
--         switch ( controlState & (TDC_UP|TDC_DOWN) ) {
--             case TDC_UP:   desiredSpeed = m_maxForwardSpeed;  break;
--             case TDC_DOWN: desiredSpeed = m_maxBackwardSpeed; break;
--             default: return;//do nothing
--         }
-- 
--         //find current speed in forward direction
--         b2Vec2 currentForwardNormal = m_body->GetWorldVector( b2Vec2(0,1) );
--         float currentSpeed = b2Dot( getForwardVelocity(), currentForwardNormal );
-- 
--         //apply necessary force
--         float force = 0;
--         if ( desiredSpeed > currentSpeed )
--             force = m_maxDriveForce;
--         else if ( desiredSpeed < currentSpeed )
--             force = -m_maxDriveForce;
--         else
--             return;
--         m_body->ApplyForce( m_currentTraction * force * currentForwardNormal, m_body->GetWorldCenter() );
--     }
-- 
--     void updateTurn(int controlState) {
--         float desiredTorque = 0;
--         switch ( controlState & (TDC_LEFT|TDC_RIGHT) ) {
--             case TDC_LEFT:  desiredTorque = 15;  break;
--             case TDC_RIGHT: desiredTorque = -15; break;
--             default: ;//nothing
--         }
--         m_body->ApplyTorque( desiredTorque );
--     }
-- };

return Wheel