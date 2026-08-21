# Purchase Approval Workflow (n8n)

> Don't have n8n running yet? See [`README-setup.md`](README-setup.md) to install and start it
> locally first.

This is a hands-on build exercise — you build this workflow yourself in the n8n editor, node by
node. This README only covers the **external setup** you'll need along the way (an email
credential, a place to log to); it deliberately doesn't describe the workflow's structure or
logic — that's the exercise.

Everything you'll need is free: n8n's built-in Data Table needs no external service at all, and
sending email needs only an SMTP credential you set up yourself (a free Ethereal test inbox, or
your own Gmail account — see below). No paid nodes, no paid services.

## Setting up an SMTP credential (for sending an email from the workflow)

Easiest free option with a real inbox? Use your own email provider's SMTP (e.g. a Gmail app
password — see [README-setup-gmail.md](README-setup-gmail.md)).

## Setting up a Data Table (for logging)

In the left sidebar: **Data Tables → + Add Data Table**. Give it a name and add whatever columns
fit what you're logging — the schema is part of the exercise, not something to look up here.
Once it exists, any Data Table node in your workflow can point at it via its **Data table**
field.

## n8n platform gotchas worth knowing

General n8n behaviors that aren't obvious from the docs and can cost you time regardless of what
you're building:

- **A Form Trigger's custom path lives in its Options → Path field, not the top-level Path
  field.** The top-level field only applies to node version ≤2.1; from 2.2 onward it's silently
  ignored, and n8n falls back to using the node's raw webhook ID as the URL instead. If your
  form's URL looks like a UUID instead of your intended slug, this is why.
- **`responseMode: lastNode` alone does not render a page.** It just tells the trigger to wait
  for the workflow to finish. You still need a **Form** node (not Form Trigger) with operation
  **"completion"** as the actual last node in a branch to render a confirmation screen —
  otherwise the submission succeeds (visible in the execution log) but the browser gets an empty
  response.
- **Submitted form field values arrive keyed by position (`field-0`, `field-1`, …) at the raw
  HTTP layer**, not by your field's name — n8n's own client-side JS remaps them to your
  configured field name before your workflow ever sees them. Only matters if you're scripting
  submissions directly instead of using the rendered form.
- **A Webhook node** (if you use one instead of Form Trigger) **nests POST data under
  `$json.body`**, not directly on `$json`. Form Trigger doesn't have this problem — its output
  fields are flat.
- **Ethereal's SMTP uses STARTTLS on port 587, not implicit TLS** — the credential's `SSL/TLS`
  toggle must be **off** for port 587 to work (a confusingly-named setting: off means "use
  STARTTLS," not "no encryption at all").
- **A Data Table node's Data table field is per-instance** — it references a table ID that only
  exists on the n8n instance it was configured on. If you ever export/share a workflow, whoever
  imports it will need to repoint this field at their own table.

## Reference

- [n8n Form Trigger node](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.formtrigger/)
- [n8n Form node](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.form/)
- [n8n If node](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.if/)
- [n8n Edit Fields (Set) node](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.set/)
- [n8n Data Table node](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.datatable/)
- [n8n Send Email node](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.sendemail/)
- [Ethereal Email](https://ethereal.email/) — free fake SMTP for testing
- [n8n free / self-hosted plans](https://n8n.io/pricing/)
