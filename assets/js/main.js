/**
SPDX-FileCopyrightText: 2026 Claire Tam <claire2026t@posteo.net>
SPDX-License-Identifier: MIT
**/

// Block actions, declared in templates as <button data-action="name">
// (see layouts/_partials/code-block.html). To add one: add an entry here,
// list its name in a render hook's "actions", and add i18n key code_<name>.
const actions = {
    // Copy the block's source text (TeX source for KaTeX equations)
    copy: {
        available: () => Boolean(navigator.clipboard), // needs HTTPS or localhost
        run: (block) => {
            const tex = block.querySelector('annotation[encoding="application/x-tex"]');
            if (tex) return navigator.clipboard.writeText(tex.textContent.trim());

            // With table-style line numbers the last <code> holds the source
            const codes = block.querySelectorAll(".code-content code");
            const code = codes[codes.length - 1].cloneNode(true);
            code.querySelectorAll(".ln").forEach((n) => n.remove()); // inline line numbers
            return navigator.clipboard.writeText(code.textContent);
        },
    },

    // Open the rendered diagram as a standalone SVG at full size
    open: {
        available: () => true,
        run: (block) => {
            const svg = block.querySelector(".code-content svg");
            if (!svg) throw new Error("not rendered yet");
            const blob = new Blob([new XMLSerializer().serializeToString(svg)], { type: "image/svg+xml" });
            window.open(URL.createObjectURL(blob), "_blank", "noopener");
        },
    },
};

document.addEventListener("DOMContentLoaded", () => {
    for (const button of document.querySelectorAll("[data-action]")) {
        if (actions[button.dataset.action]?.available()) button.hidden = false;
    }
});

document.addEventListener("click", async (event) => {
    const button = event.target.closest("[data-action]");
    const action = button && actions[button.dataset.action];
    if (!action) return;

    try {
        await action.run(button.closest(".code-wrapper"));
    } catch {
        return;
    }

    // Brief feedback, if the action has a code_<name>_done label
    const { done } = button.dataset;
    if (!done || button.dataset.label) return;
    button.dataset.label = button.textContent;
    button.textContent = done;
    setTimeout(() => {
        button.textContent = button.dataset.label;
        delete button.dataset.label;
    }, 1500);
});
