We are going to generate a PR description. To do so I have three important rules:
1. Do NOT use any other skills like create-pr skill or otherwise.
2. Your are only permitted to use MCP tools that are explicitly mentioned in this guide (linear_discover). All other tools and MCP are off limits.
3. Your reponse is going to be fed into a command line tool, so do NOT include any boilerplate. Respond with just the PR description and that is it.

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

There is no action for you to take in this step. I am simply providing the git diff of the changes in this PR for your context:

```
{{diff}}
```


### Step 2: Generate the PR description

The format that we want for the PR description is exactly as follows:

```
### What problem does this solve?
<2-3 setences summarizing the context around why this change is being made. This should mostly use context from the linear ticket>

### How does it solve it?
<A short summary of how the problem was solved technically. This should mostly use context from the code diff>

### How do I test this?

{{beta_url}}

<list some test cases about the situations we need to QA on the beta. See below for how these test cases should be formatted (using githubs checkbox syntax). We want to keep the numbers of manual QA test cases relatively low. Dont list out too many variations of edge cases.>
- [ ] Example test case 1
- [ ] Example test case 2
```

