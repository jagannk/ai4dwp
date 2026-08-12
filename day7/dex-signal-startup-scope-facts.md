# DEX Signal – Startup Performance Scope Facts

**Source:** Digital Employee Experience — Startup Performance export  
**Date analysed:** 2026-08-12  
**Instruction:** Scope facts only. No causal hypotheses.

---

## Scope Facts

**1. Device group affected and size**  
- Group: Finance-Win11  
- Size: 215 devices

---

**2. What changed and exactly when**  
- A new security baseline configuration profile was deployed to the Finance-Win11 group only  
- Deployment timestamp: **2026-08-04 at 02:00**  
- Changes included in the deployment:  
  - Startup script added for compliance logging  
  - Additional Defender scan policy applied

---

**3. Magnitude of the score drop**  
- Score on 2026-08-03 (last pre-change day): **84**  
- Score on 2026-08-04 (first post-change day): **61**  
- Score drop: **−23 points in a single day**  
- Median startup time on 2026-08-03: **17.5 seconds**  
- Median startup time on 2026-08-04: **41.3 seconds**  
- Startup time increase: **+23.8 seconds (+136%)**  
- Score remained depressed through 2026-08-06 (range: 59–61), showing no recovery

---

**4. Comparison group**  
- Group: IT-Win11  
- Size: 40 devices  
- Scope of config change: **Not in scope** — config change was not applied to this group  
- IT-Win11 scores over the same period:  
  - 2026-08-03: 85 (17.1 sec)  
  - 2026-08-04: 84 (17.1 sec)  
  - 2026-08-05: 85 (16.9 sec)  
- Finding: **No degradation in the comparison group across the same dates**

---

*End of scope facts — no causal analysis included*
