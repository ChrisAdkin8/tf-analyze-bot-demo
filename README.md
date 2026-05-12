# tf-analyze-bot-demo

Live demo of the [**tf-analyze auto-remediation PR bot**](https://github.com/ChrisAdkin8/tf-analyze/blob/main/integrations/github-action-bot.yml) running against a deliberately-vulnerable Terraform repository.

The bot scans this repo on a schedule, applies safe (`fix_disruption: none`) HCL fixes from the rule catalogue, and opens **one PR per scan** grouped by rule family. Think Dependabot, for Terraform security findings.

## What's in here

| File | Purpose |
|---|---|
| [`main.tf`](main.tf) | Five intentionally-broken AWS resources that the bot can remediate. Every bug is annotated with the rule ID that flags it. |
| [`.github/workflows/tf-analyze-bot.yml`](.github/workflows/tf-analyze-bot.yml) | The bot workflow — an unmodified copy of [`integrations/github-action-bot.yml`](https://github.com/ChrisAdkin8/tf-analyze/blob/main/integrations/github-action-bot.yml) from the parent project. |

## Seeded issues — all bot-fixable

| Resource | Rule | `fix_disruption` |
|---|---|---|
| `aws_ecr_repository.app` (no scan-on-push) | [`SEC-AWS-ECR-001`](https://chrisadkin8.github.io/tf-analyze/rules/SEC-AWS-ECR-001/) | `none` |
| `aws_ecr_repository.app` (no lifecycle policy) | [`SEC-AWS-ECR-002`](https://chrisadkin8.github.io/tf-analyze/rules/SEC-AWS-ECR-002/) | `none` |
| `aws_cloudwatch_log_group.app` (no CMK) | [`SEC-AWS-CWL-001`](https://chrisadkin8.github.io/tf-analyze/rules/SEC-AWS-CWL-001/) | `none` |
| `aws_cloudfront_distribution.cdn` (`viewer_protocol_policy = "allow-all"`) | [`SEC-AWS-CLOUDFRONT-001`](https://chrisadkin8.github.io/tf-analyze/rules/SEC-AWS-CLOUDFRONT-001/) | `none` |
| `aws_s3_bucket.artifacts` (no paired public-access-block) | [`SEC-AWS-S3-PUBLIC-BLOCK-001`](https://chrisadkin8.github.io/tf-analyze/rules/SEC-AWS-S3-PUBLIC-BLOCK-001/) | `none` |

Each finding's `fix_hcl` snippet is editable HCL, anchored to the file + line where the violation lives, so the bot's regex-based patcher can splice it in without rewriting the surrounding file.

## See it run

1. **Live PR** — visit the [Pull requests](../../pulls) tab. The bot opens a single `tf-analyze-bot/auto-fixes` branch and force-pushes on each scheduled run, so there is at most one open PR.
2. **Workflow runs** — the [Actions tab](../../actions/workflows/tf-analyze-bot.yml) shows every scan, including `workflow_dispatch` invocations. Click any run to expand the PR-body that was rendered for that pass.
3. **Trigger one yourself** — fork this repo, then from the Actions tab pick **tf-analyze-bot — auto-remediation PR** → **Run workflow**. You can override `max-disruption` to `plan_required` if you want to see the higher-trust tier in action.

## Reproducing locally

```bash
git clone https://github.com/ChrisAdkin8/tf-analyze.git /tmp/tf-analyze
git clone https://github.com/ChrisAdkin8/tf-analyze-bot-demo.git
cd tf-analyze-bot-demo

# Dry-run (prints which fixes would land, changes nothing on disk).
python3 /tmp/tf-analyze/scripts/detect.py \
  --target . \
  --catalog /tmp/tf-analyze/catalog \
  --apply-fixes dry-run \
  --apply-fixes-max-disruption none

# Apply for real.
python3 /tmp/tf-analyze/scripts/detect.py \
  --target . \
  --catalog /tmp/tf-analyze/catalog \
  --apply-fixes apply \
  --apply-fixes-max-disruption none
git diff
```

## Caveats

- This repo is **deliberately vulnerable**. Don't `terraform apply` it. There is no backend configured, but if you point a real AWS account at it you will provision an unencrypted CloudFront distribution and a public-by-default S3 bucket.
- The bot's apply step exits cleanly when there is nothing to fix. After the first run merges its PR, subsequent runs no-op until a new seed bug is added — this is the intended Dependabot-style cadence.
- Bot eligibility is `fix_disruption: none` only. Roughly 150 of 238 catalogue rules qualify; the rest require a `forces_replacement` apply that the bot won't perform unsupervised.

## Source

- Parent project: [github.com/ChrisAdkin8/tf-analyze](https://github.com/ChrisAdkin8/tf-analyze)
- Bot workflow: [`integrations/github-action-bot.yml`](https://github.com/ChrisAdkin8/tf-analyze/blob/main/integrations/github-action-bot.yml)
- Bot internals: [`integrations/github-action-bot/`](https://github.com/ChrisAdkin8/tf-analyze/tree/main/integrations/github-action-bot)
- Docs: [chrisadkin8.github.io/tf-analyze/github-action-bot](https://chrisadkin8.github.io/tf-analyze/github-action-bot)
