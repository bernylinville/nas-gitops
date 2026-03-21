---
name: ansible-zen
description: >-
  Display the Zen of Ansible principles and review Ansible code against
  them for simplicity, readability, and clarity. Use when user says "zen
  of ansible", "simplify my playbook", "is this too complex", or "clean
  code review". Complements ansible-cop-review with philosophical guidance.
  Do NOT use for strict rule compliance (use ansible-cop-review instead).
argument-hint: "[path or files]"
user-invocable: true
metadata:
  author: Leonardo Gallego (original), adapted for nas-gitops
  version: 1.1.0
---

# The Zen of Ansible

## Important

- This is **complementary** to `ansible-cop-review`. Zen focuses on
  philosophy and style; CoP focuses on rule compliance.
- Keep feedback constructive and encouraging.
- When showing improved code, explain *why* it's better.
- If code is well-aligned with Zen, say so.

## The Principles

```
 1. Ansible is not Python.
 2. YAML sucks for coding.
 3. Playbooks are not for programming.
 4. Ansible users are (most likely) not programmers.
 5. Clear is better than cluttered.
 6. Concise is better than verbose.
 7. Simple is better than complex.
 8. Readability counts.
 9. Helping users get things done matters most.
10. User experience beats ideological purity.
11. "Magic" conquers the manual.
12. When giving users options, use convention over configuration.
13. Declarative is better than imperative -- most of the time.
14. Focus avoids complexity.
15. Complexity kills productivity.
16. If the implementation is hard to explain, it's a bad idea.
17. Every shell command and UI interaction is an opportunity to automate.
18. Just because something works, doesn't mean it can't be improved.
19. Friction should be eliminated whenever possible.
20. Automation is a journey that never ends.
```

## Modes

### Mode 1: Display the Zen

If invoked without arguments, display the full Zen. Pick one random
principle and explain it with a practical NAS-related Ansible example
(good vs bad, 5-10 lines each).

### Mode 2: Review code

If arguments contain a path or files, review Ansible code against Zen
principles. Focus on simplicity, readability, and clarity.

#### Review process

1. Discover and read files
2. Evaluate against applicable principles
3. Report findings grouped by principle:
   - Principle violated
   - File path and line number
   - Offending snippet
   - Improved version
   - Why the change aligns with the principle
4. **Zen Score** (1-10):
   - 9-10: Exemplary
   - 7-8: Good
   - 5-6: Acceptable
   - 3-4: Needs work
   - 1-2: Anti-Zen
5. Top 3 most impactful recommendations
