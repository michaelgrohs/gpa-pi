# AI Email Triage Workflow (n8n)

> Don't have n8n running yet? See [`README-setup.md`](README-setup.md) to install and start it
> locally first.

This is a hands-on build exercise — you build this workflow yourself in the n8n editor, node by
node. The goal: an incoming email gets read by a local AI model and classified into departments
(e.g. Sales / Support / Billing) automatically, with the decision logged somewhere visible. This
README only covers the **external setup** you'll need along the way (a local model, a mailbox, a
place to log to); it deliberately doesn't describe the workflow's structure or logic — that's the
exercise.

## Setting up Ollama (local AI model)

Install Ollama (if you don't have it already): [ollama.com](https://ollama.com/download). Then
pull a model:

```bash
ollama pull llama3.1:8b
```

Ollama runs as a background service after install — no need to start it manually. (A larger
model classifies more reliably than a small one — see "Known limitations" below.)

### The Ollama credential in n8n

When you add a node that connects to a local model, open its **Credential** field → **Create
New**. Set **Base URL** to `http://127.0.0.1:11434` — **use `127.0.0.1`, not `localhost`** (see
the gotcha below). No API key needed.

## Setting up a Data Table (for logging)

In the left sidebar: **Data Tables → + Add Data Table**. Give it a name and add whatever columns
fit what you're logging — the schema is part of the exercise, not something to look up here.

## Connecting your mailbox (IMAP)

Open the credential dialog on your mail-reading node → **Create New** → **IMAP**. For Gmail
specifically, see [README-setup-gmail.md](README-setup-gmail.md) for the full app-password setup
— short version:

- **User**: your full Gmail address
- **Password**: a Gmail app password (not your normal password)
- **Host**: `imap.gmail.com`
- **Port**: `993`
- **SSL/TLS**: on

## Testing it

Send yourself (or have someone send) a test email to the connected inbox. Check wherever you're
logging to afterward — n8n's **Executions** list also shows each run so you can inspect exactly
what the AI decided and why.

## Known limitations of local AI models (worth knowing before you design your error handling)

Local, smaller AI models are meaningfully less reliable at strict structured classification than
large cloud models (GPT, Gemini, Claude). In repeated testing with `llama3.1:8b` against sample
emails, two failure modes showed up — worth designing around rather than assuming won't happen:

- **Double-classification.** Even when a classifier is instructed that only one category should
  match, there's no hard guarantee — a borderline email can get flagged as belonging to more than
  one category.


## Gotcha: use `127.0.0.1`, not `localhost`, for the Ollama credential

n8n's internal HTTP client can fail to connect using `http://localhost:11434` even though Ollama
is running and reachable — plain `curl` and Node's own `fetch` both connect fine to the same
address. This points to an IPv4/IPv6 resolution mismatch (Ollama listens on `127.0.0.1` only;
n8n's client likely tries `::1` first and doesn't fall back). Using the explicit IPv4 address
(`http://127.0.0.1:11434`) fixes it immediately and consistently.

## Reference

- [n8n Email Trigger (IMAP) node](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.emailimap/)
- [n8n Text Classifier node](https://docs.n8n.io/integrations/builtin/cluster-nodes/root-nodes/n8n-nodes-langchain.text-classifier/)
- [n8n Ollama Chat Model node](https://docs.n8n.io/integrations/builtin/cluster-nodes/sub-nodes/n8n-nodes-langchain.lmchatollama/)
- [n8n Data Table node](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.datatable/)
- [Ollama](https://ollama.com/) — free, local AI model runner
