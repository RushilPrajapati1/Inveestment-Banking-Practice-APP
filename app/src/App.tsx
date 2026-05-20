import { useEffect, useMemo, useRef, useState } from "react";
import "./App.css";
import { Answer } from "./Answer";
import { allQuestions, categories, categoryLabel, groups } from "./data";
import type { Question } from "./types";
import { useProgress } from "./useProgress";

type Mode = "browse" | "cards";
type DiffFilter = "all" | "Basic" | "Advanced";

export default function App() {
  const { map, toggle, setStatus, reset } = useProgress();
  const [mode, setMode] = useState<Mode>("browse");
  const [activeSlug, setActiveSlug] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [diff, setDiff] = useState<DiffFilter>("all");
  const [onlyReview, setOnlyReview] = useState(false);

  const known = useMemo(
    () => Object.values(map).filter((s) => s === "known").length,
    [map],
  );

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return allQuestions.filter((item) => {
      if (activeSlug && categorySlug(item) !== activeSlug) return false;
      if (diff !== "all" && item.difficulty !== diff) return false;
      if (onlyReview && map[item.id] !== "review") return false;
      if (q) {
        const hay = (item.question + " " + item.answer).toLowerCase();
        if (!hay.includes(q)) return false;
      }
      return true;
    });
  }, [query, activeSlug, diff, onlyReview, map]);

  return (
    <div className="app">
      <Sidebar
        activeSlug={activeSlug}
        setActiveSlug={setActiveSlug}
        progress={map}
        total={allQuestions.length}
        known={known}
        onReset={reset}
      />

      <main className="main">
        <header className="topbar">
          <div className="search">
            <input
              type="search"
              placeholder="Search 400 questions & answers…"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              autoFocus
            />
          </div>
          <div className="controls">
            <div className="seg">
              <button
                className={mode === "browse" ? "on" : ""}
                onClick={() => setMode("browse")}
              >
                Browse
              </button>
              <button
                className={mode === "cards" ? "on" : ""}
                onClick={() => setMode("cards")}
              >
                Flashcards
              </button>
            </div>
            <select value={diff} onChange={(e) => setDiff(e.target.value as DiffFilter)}>
              <option value="all">All levels</option>
              <option value="Basic">Basic</option>
              <option value="Advanced">Advanced</option>
            </select>
            <label className="check">
              <input
                type="checkbox"
                checked={onlyReview}
                onChange={(e) => setOnlyReview(e.target.checked)}
              />
              Review only
            </label>
          </div>
        </header>

        <div className="meta">
          {filtered.length} question{filtered.length === 1 ? "" : "s"}
          {activeSlug
            ? ` · ${categoryLabel(categoryBySlug(activeSlug)!)}`
            : " · all categories"}
          {query ? ` · matching “${query}”` : ""}
        </div>

        {mode === "browse" ? (
          <BrowseView items={filtered} progress={map} toggle={toggle} />
        ) : (
          <CardsView items={filtered} progress={map} setStatus={setStatus} />
        )}
      </main>
    </div>
  );
}

function categorySlug(q: Question): string {
  const c = categories.find(
    (c) => c.name === q.category && c.difficulty === q.difficulty,
  );
  return c ? c.slug : "";
}

function categoryBySlug(slug: string) {
  return categories.find((c) => c.slug === slug) ?? null;
}

/* ---------------- Sidebar ---------------- */

function Sidebar({
  activeSlug,
  setActiveSlug,
  progress,
  total,
  known,
  onReset,
}: {
  activeSlug: string | null;
  setActiveSlug: (s: string | null) => void;
  progress: Record<string, string>;
  total: number;
  known: number;
  onReset: () => void;
}) {
  const pct = total ? Math.round((known / total) * 100) : 0;
  return (
    <aside className="sidebar">
      <div className="brand">
        <h1>400 IB Questions</h1>
        <p>Investment Banking interview prep</p>
      </div>

      <div className="progress-card">
        <div className="progress-top">
          <span>{known} known</span>
          <span>{pct}%</span>
        </div>
        <div className="bar">
          <div className="bar-fill" style={{ width: `${pct}%` }} />
        </div>
        <button className="link" onClick={onReset}>
          Reset progress
        </button>
      </div>

      <nav className="nav">
        <button
          className={activeSlug === null ? "cat all on" : "cat all"}
          onClick={() => setActiveSlug(null)}
        >
          <span>All questions</span>
          <span className="count">{total}</span>
        </button>

        {groups.map((g) => (
          <div className="group" key={g.name}>
            <div className="group-title">{g.name}</div>
            {g.categories.map((c) => {
              const cKnown = c.questions.filter(
                (q) => progress[q.id] === "known",
              ).length;
              return (
                <button
                  key={c.slug}
                  className={c.slug === activeSlug ? "cat on" : "cat"}
                  onClick={() => setActiveSlug(c.slug)}
                >
                  <span className="cat-name">
                    {c.name}
                    {c.difficulty ? (
                      <em className={`tag ${c.difficulty.toLowerCase()}`}>
                        {c.difficulty}
                      </em>
                    ) : null}
                  </span>
                  <span className="count">
                    {cKnown}/{c.count}
                  </span>
                </button>
              );
            })}
          </div>
        ))}
      </nav>
    </aside>
  );
}

/* ---------------- Browse ---------------- */

function BrowseView({
  items,
  progress,
  toggle,
}: {
  items: Question[];
  progress: Record<string, string>;
  toggle: (id: string, status: "known" | "review") => void;
}) {
  const [open, setOpen] = useState<Set<string>>(new Set());

  if (items.length === 0) return <Empty />;

  const toggleOpen = (id: string) =>
    setOpen((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });

  return (
    <ul className="list">
      {items.map((q) => {
        const isOpen = open.has(q.id);
        const status = progress[q.id];
        return (
          <li key={q.id} className={`row ${status ?? ""}`}>
            <button className="row-q" onClick={() => toggleOpen(q.id)}>
              <span className={`chev ${isOpen ? "open" : ""}`}>▸</span>
              <span className="q-text">{q.question}</span>
              {q.difficulty ? (
                <em className={`tag ${q.difficulty.toLowerCase()}`}>
                  {q.difficulty}
                </em>
              ) : null}
            </button>
            {isOpen && (
              <div className="row-a">
                <div className="answer">
                  <Answer text={q.answer} />
                </div>
                <div className="mark">
                  <button
                    className={status === "known" ? "known on" : "known"}
                    onClick={() => toggle(q.id, "known")}
                  >
                    ✓ Known
                  </button>
                  <button
                    className={status === "review" ? "review on" : "review"}
                    onClick={() => toggle(q.id, "review")}
                  >
                    ↺ Review
                  </button>
                  <span className="src">{q.category}</span>
                </div>
              </div>
            )}
          </li>
        );
      })}
    </ul>
  );
}

/* ---------------- Flashcards ---------------- */

function CardsView({
  items,
  progress,
  setStatus,
}: {
  items: Question[];
  progress: Record<string, string>;
  setStatus: (id: string, status: "known" | "review" | null) => void;
}) {
  const [order, setOrder] = useState<number[]>([]);
  const [pos, setPos] = useState(0);
  const [flipped, setFlipped] = useState(false);
  const signature = items.map((i) => i.id).join("|");
  const lastSig = useRef("");

  // Rebuild the deck whenever the filtered set changes.
  useEffect(() => {
    if (signature !== lastSig.current) {
      lastSig.current = signature;
      setOrder(items.map((_, i) => i));
      setPos(0);
      setFlipped(false);
    }
  }, [signature, items]);

  if (items.length === 0) return <Empty />;

  const idx = order[pos] ?? 0;
  const q = items[idx];
  if (!q) return <Empty />;
  const status = progress[q.id];

  const go = (delta: number) => {
    setFlipped(false);
    setPos((p) => Math.max(0, Math.min(order.length - 1, p + delta)));
  };
  const shuffle = () => {
    const next = [...order];
    for (let i = next.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [next[i], next[j]] = [next[j], next[i]];
    }
    setOrder(next);
    setPos(0);
    setFlipped(false);
  };
  const mark = (s: "known" | "review") => {
    setStatus(q.id, status === s ? null : s);
    if (pos < order.length - 1) go(1);
  };

  return (
    <div className="cards">
      <div className="cards-bar">
        <span>
          {pos + 1} / {order.length}
        </span>
        <button className="link" onClick={shuffle}>
          ⤮ Shuffle
        </button>
      </div>

      <div
        className={`card ${flipped ? "flipped" : ""} ${status ?? ""}`}
        onClick={() => setFlipped((f) => !f)}
      >
        <div className="card-cat">
          {q.category}
          {q.difficulty ? ` · ${q.difficulty}` : ""}
        </div>
        {!flipped ? (
          <div className="card-front">
            <p className="card-q">{q.question}</p>
            <span className="hint">Click to reveal answer</span>
          </div>
        ) : (
          <div className="card-back">
            <Answer text={q.answer} />
          </div>
        )}
      </div>

      <div className="cards-actions">
        <button onClick={() => go(-1)} disabled={pos === 0}>
          ← Prev
        </button>
        <button
          className={status === "review" ? "review on" : "review"}
          onClick={() => mark("review")}
        >
          ↺ Review
        </button>
        <button
          className={status === "known" ? "known on" : "known"}
          onClick={() => mark("known")}
        >
          ✓ Known
        </button>
        <button onClick={() => go(1)} disabled={pos === order.length - 1}>
          Next →
        </button>
      </div>
    </div>
  );
}

function Empty() {
  return (
    <div className="empty">
      <p>No questions match your filters.</p>
    </div>
  );
}
