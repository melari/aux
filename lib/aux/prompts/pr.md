We are going to generate a PR title and description. Important rules:
1. Do NOT use any other skills like create-pr skill or otherwise.
2. You are only permitted to use MCP tools that are explicitly mentioned in this guide (linear_discover). All other tools and MCP are off limits.
3. Your response will be machine-parsed as JSON. Respond with ONLY a valid JSON object — no markdown fences, no boilerplate, nothing else.

Example JSON response:
{
  title: "The title",
  description: "The description"
}

### Step 1a: Gather context from Linear

The branch name of the code change is {{branch}}. It should include information about the linear TICKET_ID.

- Use the `linear_discover` MCP tool to fetch ticket details with relationships:
    ```json
    {
    "server": "user-linear",
    "toolName": "linear_discover",
    "arguments": {
        "action": "get-issue",
        "issue_id": "<TICKET_ID>",
        "include_relationships": true
    }
    }
    ```
- Extract: title, description, and acceptance criteria
- **If the ticket is a subtask** (has a parent):
    - Fetch the parent ticket to understand the broader context/goal
    - Note any sibling subtasks to understand how this work fits into the larger effort
    - The parent's description often contains the overall requirements. If not, rely on the sibling tickets to get overall requirements.
- It's possible that there is no Linear ticket, or you are unable to infer the linear ticket ID from the branch name. In this case just skip this context gathering step and do your best with what you have.

### Step 1b: Context from Git

There is no action for you to take in this step. I am simply providing the commit history and git diff of the changes in this PR for your context.

Commits (newest first):
```
{{commits}}
```

Diff:
```
{{diff}}
```

### Step 2: Generate the PR title and description

**Title:** A single concise PR title in the imperative mood (e.g. "Add", "Fix", "Update"), suitable as a GitHub PR title.

**Description:** Use exactly this format:

### What problem does this solve?
<2-3 sentences summarizing the context around why this change is being made. This should mostly use context from the linear ticket>

### How does it solve it?
<A short summary of how the problem was solved technically. This should mostly use context from the code diff>

### How do I test this?

{{beta_url}}

<list some test cases about the situations we need to QA on the beta. Use GitHub checkbox syntax. Keep the number of manual QA test cases relatively low — don't list too many edge case variations.>
- [ ] Example test case 1
- [ ] Example test case 2

Respond with ONLY this JSON object (no markdown fences):
{"title": "<pr title>", "description": "<pr description>"}
