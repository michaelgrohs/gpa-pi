# 08_GPA-PI

Course materials for business process automation and RPA. Top-level folders are numbered
course modules (`02_...`, `04_...`); expect more to be added over time.

## Python setup (needed for `04_RPA-in-Action/scraping`)

Create a virtual environment here at the repo root, then install dependencies into it from
`requirements.txt` — don't `pip install` straight into your system/global Python.

**macOS / Linux:**

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

**Windows (PowerShell):**

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

Then open `04_RPA-in-Action/scraping/sp500_rpa_exercise.ipynb` and select this `.venv` as the
notebook's kernel (in VS Code/Jupyter's kernel picker, look for the interpreter path ending in
`.venv`) before running any cells. The notebook's first cell also runs a `%pip install ...` for
the same packages — with everything already installed via `requirements.txt` that cell will just
report the requirements are already satisfied, which is expected.

Each time you come back to work on this, re-activate the venv (`source .venv/bin/activate` /
`.\.venv\Scripts\Activate.ps1`) before launching Jupyter/VS Code from that terminal.

`rpaframework` (used by the scraping exercise) drives a real Chrome or Firefox browser via
Selenium, so one of those needs to be installed locally.

## Module index

- `02_Business-Process-Automation/` — reading material and process descriptions used as
  exercise input for process-modeling work.
- `04_RPA-in-Action/` — hands-on RPA exercises: n8n workflows (`n8n/`) and a Python/Jupyter
  web-scraping mini-project (`scraping/`).
