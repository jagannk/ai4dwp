Summary (one line)
New Win11 laptop repeatedly prompts for BitLocker recovery key at every boot, preventing normal startup.

Impact (who/how many/ business urgency)
Who: Single end user (to-verify).
How many: One device reported (to-verify).
Business urgency: to-verify (device may be unable to boot to full OS until recovery key is entered).

known facts
- Device is newly provisioned Win11 laptop.
- BitLocker recovery key prompt appears at every boot.
- Issue persists—not a one-time event.
- User reports inability to proceed past recovery prompt without entering key (to-verify).

Missing information to gather
- How is BitLocker recovery key prompt being triggered? (Startup repair, TPM error, PIN/password misconfiguration, failed BitLocker unlock—to-verify)
- What exact message/code appears on the prompt screen (to-verify).
- Is device encrypted via Intune MDM policy, Group Policy, or manual BitLocker enable (to-verify).
- Can the user successfully boot after entering recovery key, or does issue recur (to-verify).
- TPM 2.0 status and firmware version (to-verify).
- Whether BIOS/UEFI Secure Boot and TPM settings are enabled/configured correctly (to-verify).
- Recent device history: any failed boot attempts, BIOS updates, or firmware changes since provisioning (to-verify).
- Is this issue isolated to one device or affecting other new Win11 laptops in cohort (to-verify).

likely catagory
BitLocker startup configuration and TPM initialization incident (to-verify).

Suggest first diagnostic step
Collect device details and boot state: confirm BitLocker encryption status and recovery mechanism via PowerShell or manage-bde; verify TPM 2.0 presence and health; check for pending BIOS/driver updates; escalate to device provisioning/imaging team to confirm BitLocker policy intent and whether recovery key escrow is properly configured in tenant (to-verify).
