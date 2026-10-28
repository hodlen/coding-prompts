# Local review IO

| Contract | Caller can rely on |
|---|---|
| Input | One self-contained HTML file packed with this skill's runtime. |
| Browser transport | One random URL on `127.0.0.1`, with the page and receiver on the same origin. |
| Output | The URL and errors go to stderr. Exact response Markdown goes to stdout and a response file. |
| Lifetime | The command waits for one accepted response, then closes its server and exits. It has no review timeout. |
| Browser receipt | HTTP success and JSON `{"received":true}` permit the page to attempt closure. |

## Start and retain the receiver

```sh
node <skill dir>/runtime/review.mjs plan.packed.html
```

The default output is the sibling `plan.response.md`; use `--out feedback.md` to choose another path. An existing output file is overwritten. The output must not identify the input file, including through a symlink or hard link. Use a distinct path to preserve an earlier response.

Pack with the current runtime before the handoff. The packed file contains its own JavaScript; starting a new receiver does not update that embedded code.

Run the receiver as a harness-managed task and keep its handle and output path. Keep the task owner alive until the review ends; do not detach with shell `&`. Collect the output and exit status before acting on the response. If the harness provides no completion notification, keep an active wait when automatic continuation is required. The harness can end the task even though the receiver has no review timeout.

The receiver adds `<meta name="htmlplan-response" content="...">` only to the served copy. The original packed file keeps its standalone copy workflow.

## Open the page in its host

Open the printed URL in one user-facing review tab with the harness's browser tools. Use the host's built-in browser when available. Confirm the page title or test marker. Reuse this tab for inspection: the receiver accepts one response across all copies.

## Receipt, exit, and retry

Respond posts the current Markdown as `text/plain` to the metadata endpoint. Invalid paths, methods, origins, and empty bodies leave the receiver waiting. Saving the response precedes the positive ACK. The success path lets the HTTP connection close normally so shutdown does not forcefully interrupt that connection. It then ends other unfinished requests.

The page disables Respond while sending. It requires both a successful HTTP status and `{"received":true}`. HTTP, network, or invalid-ACK failures keep the page and feedback available. A positive ACK shows a receipt and calls `window.close()`; browser policy decides whether the tab actually closes.

Exit 0 means the response was saved, output, and the ACK write completed. It does not prove that the browser read the ACK. Cancellation or startup/save/ACK-write errors exit nonzero. A failed ACK write can still leave a saved response file.

If the page says **Response not confirmed** or **Failed to fetch**:

1. Preserve the page and its feedback. Inspect the retained command's output, exit status, and response file.
2. If feedback was saved, report that fact separately from the missing browser receipt. Do not ask the user to recreate it.
3. If another review is needed, start a new command, use its new URL, and preserve the earlier output. The old one-shot URL stops working after its receiver exits.

## Verify the complete interaction

Use a small disposable page when testing transport. Open it in the intended host, confirm its title or marker, change one choice, add a short Unicode comment, and press Respond. Check the saved Markdown and command output, exit status, and the browser's receipt or automatic closure. A command exit code alone is insufficient evidence of browser presentation. Test failures with the same distinction between storage and receipt.

Report page presentation, saved feedback, process completion, and browser receipt or closure separately. Keep the user's actual review available; submit its decisions only when the user authorizes that submission.
