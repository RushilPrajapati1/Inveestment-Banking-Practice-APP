import { Fragment, type ReactNode } from "react";

// The parser emits answers as blocks separated by blank lines; bullet blocks
// begin with "- ". Group consecutive bullets into a single list.
export function Answer({ text }: { text: string }) {
  const blocks = text.split(/\n{2,}/).map((b) => b.trim()).filter(Boolean);
  const out: ReactNode[] = [];
  let bullets: string[] = [];

  const flushBullets = (key: string) => {
    if (bullets.length) {
      out.push(
        <ul key={key}>
          {bullets.map((b, i) => (
            <li key={i}>{b.replace(/^-\s+/, "")}</li>
          ))}
        </ul>,
      );
      bullets = [];
    }
  };

  blocks.forEach((block, i) => {
    if (block.startsWith("- ")) {
      bullets.push(block);
    } else {
      flushBullets(`ul-${i}`);
      out.push(<p key={`p-${i}`}>{block}</p>);
    }
  });
  flushBullets("ul-end");

  return <Fragment>{out}</Fragment>;
}
