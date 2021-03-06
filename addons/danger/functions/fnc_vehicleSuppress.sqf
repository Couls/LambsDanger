#include "script_component.hpp"
/*
 * Author: nkenny
 * Vehicle performs suppressive fire on target location
 *
 * Arguments:
 * 0: vehicle suppressing <OBJECT>
 * 1: Target position <ARRAY>
 *
 * Return Value:
 * success
 *
 * Example:
 * [bob, getPos angryJoe] call lambs_danger_fnc_vehicleSuppress;
 *
 * Public: No
*/
params ["_unit", "_pos"];

// too close + high speed
if (_unit distance2d _pos < GVAR(minSuppression_range)) exitWith {false};
private _vehicle = vehicle _unit;
if (speed _vehicle > 12) exitWith {false};

// artillery (no tactical options)
if (_vehicle getVariable [QGVAR(isArtillery), getNumber (configFile >> "CfgVehicles" >> (typeOf (vehicle _unit)) >> "artilleryScanner") > 0]) exitWith {
    _vehicle setVariable [QGVAR(isArtillery), true];
    false
};

// set task
_unit setVariable [QGVAR(currentTarget), _pos, GVAR(debug_functions)];
_unit setVariable [QGVAR(currentTask), "Vehicle Suppress", GVAR(debug_functions)];

// pos
_pos = (AGLtoASL _pos) vectorAdd [0.5 - random 1, 0.5 - random 1, 0.3 + random 1.3];

// trace
private _vis = lineIntersectsSurfaces [eyePos _unit, _pos, _unit, vehicle _unit, true, 1];
if !(_vis isEqualTo []) then {_pos = (_vis select 0) select 0;};

// recheck
if (_vehicle distance (ASLToAGL _pos) < GVAR(minSuppression_range)) exitWith {false};

private _friendlys = [_vehicle, (ASLToAGL _pos), GVAR(minFriendlySuppressionDistance)] call FUNC(nearbyFriendly);
if !(_friendlys isEqualTo []) exitWith {false};

// do it
_vehicle doSuppressiveFire _pos;

// debug
if (GVAR(debug_functions)) then {

    format ["%1 suppression (%2 @ %3m)", side _unit, getText (configFile >> "CfgVehicles" >> (typeOf _vehicle) >> "displayName"), round (_unit distance ASLToAGL _pos)] call FUNC(debugLog);

    private _sphere = createSimpleObject ["Sign_Sphere100cm_F", _pos, true];
    _sphere setObjectTexture [0, [_unit] call FUNC(debugObjectColor)];
    [{deleteVehicle _this}, _sphere, 20] call CBA_fnc_waitAndExecute;
};

// end
true
