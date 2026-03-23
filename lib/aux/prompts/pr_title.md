We are going to generate a PR title. Three important rules:
1. Do NOT use any other skills like create-pr skill or otherwise.
2. You are only permitted to use MCP tools that are explicitly mentioned in this guide.
3. Your response is going to be fed directly into a command line tool. Respond with ONLY the PR title — no quotes, no punctuation prefix, no boilerplate whatsoever.

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
- Extract: title and description
- **If the ticket is a subtask** (has a parent):
    - Fetch the parent ticket to understand the broader context/goal
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

### Step 2: Generate the PR title

Write a single concise PR title that clearly describes what this change does. It should be in the imperative mood (e.g. "Add", "Fix", "Update") and be suitable as a GitHub PR title.
