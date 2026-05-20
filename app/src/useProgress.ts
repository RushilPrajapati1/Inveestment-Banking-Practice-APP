import { useCallback, useEffect, useState } from "react";

export type Status = "known" | "review";

const KEY = "ib-progress-v1";

type ProgressMap = Record<string, Status>;

function load(): ProgressMap {
  try {
    const raw = localStorage.getItem(KEY);
    return raw ? (JSON.parse(raw) as ProgressMap) : {};
  } catch {
    return {};
  }
}

export function useProgress() {
  const [map, setMap] = useState<ProgressMap>(load);

  useEffect(() => {
    try {
      localStorage.setItem(KEY, JSON.stringify(map));
    } catch {
      /* storage full or unavailable — progress is best-effort */
    }
  }, [map]);

  const setStatus = useCallback((id: string, status: Status | null) => {
    setMap((prev) => {
      const next = { ...prev };
      if (status === null) delete next[id];
      else next[id] = status;
      return next;
    });
  }, []);

  const toggle = useCallback((id: string, status: Status) => {
    setMap((prev) => {
      const next = { ...prev };
      if (next[id] === status) delete next[id];
      else next[id] = status;
      return next;
    });
  }, []);

  const reset = useCallback(() => setMap({}), []);

  return { map, setStatus, toggle, reset };
}
