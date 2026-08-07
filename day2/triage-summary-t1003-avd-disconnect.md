Summary (one line)
AVD session disconnects after approximately 10 minutes, then automatically reconnects.

Impact (who/how many/ business urgency)
Who: Single user (to-verify).
How many: One user/session reported (to-verify).
Business urgency: to-verify (recurring disconnections interrupt workflow; may affect productivity for sustained AVD sessions).

known facts
- User reports AVD session disconnects consistently after ~10 minutes.
- Session automatically reconnects after disconnect.
- Pattern is repeatable (to-verify).
- User is accessing AVD from endpoint/location unknown (to-verify).

Missing information to gather
- Is this occurring on one AVD host or multiple AVD hosts (to-verify).
- Network path and connection type (local network, VPN, public internet—to-verify).
- Exact error/disconnect message shown to user (to-verify).
- Client software version (RDP, Remote Desktop app version—to-verify).
- Are other users experiencing same issue on same AVD host (to-verify).
- AVD host event logs showing disconnect/reconnect timestamps and reason codes (to-verify).
- Whether idle timeout policy is configured or if 10-minute threshold correlates to session policy (to-verify).
- Recent changes to AVD host configuration, network settings, or client software (to-verify).

likely catagory
Azure Virtual Desktop session stability and timeout configuration incident (to-verify).

Suggest first diagnostic step
Collect AVD session telemetry and check disconnect trigger: pull AVD host event viewer logs for disconnect reason and timestamp; check AVD session idle timeout and max duration policies; verify network connectivity stability from client to AVD host (ping, packet loss); test from different client machine/location to isolate client vs. host vs. network issue; check AVD Connection Diagnostics in portal if available (to-verify).
