# Agent Instructions & Rules

## Required Skill

* **Always read `~/.agents/skills/caveman/SKILL.md` before starting any task.**
* Treat the instructions in `~/.agents/skills/caveman/SKILL.md` as mandatory and apply them throughout the task.
* If the file cannot be read or does not exist, report the issue before proceeding.

## Context and Memory

* **Always read `.agents/CONTEXT.md`** before starting work if the file exists and has not already been read in the current session.
* **Always read `.agents/MEMORY.md`** before starting work if the file exists and has not already been read in the current session.

## Implementation Summary

* After completing a feature or significant implementation, update `.agents/SUMMARY.md`.
* Keep the summary **very short and concise**.
* Include only the key changes, decisions, and relevant implementation details.

## Memory

* When you learn a new, reusable fact, preference, requirement, or instruction from the user, record it in `.agents/MEMORY.md`.
* Record user instructions that are likely to be repeated or relevant to future tasks.
* Do not record temporary, task-specific, or irrelevant information.
