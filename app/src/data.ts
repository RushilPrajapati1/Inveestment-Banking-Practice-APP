import raw from "./data/questions.json";
import type { Category, Dataset, Question } from "./types";

const dataset = raw as Dataset;

export const categories: Category[] = dataset.categories;

export const allQuestions: Question[] = categories.flatMap((c) => c.questions);

export interface Group {
  name: string;
  categories: Category[];
  count: number;
}

// Preserve the category order from the source while grouping.
export const groups: Group[] = (() => {
  const order: string[] = [];
  const byGroup = new Map<string, Category[]>();
  for (const c of categories) {
    if (!byGroup.has(c.group)) {
      byGroup.set(c.group, []);
      order.push(c.group);
    }
    byGroup.get(c.group)!.push(c);
  }
  return order.map((name) => {
    const cats = byGroup.get(name)!;
    return {
      name,
      categories: cats,
      count: cats.reduce((s, c) => s + c.count, 0),
    };
  });
})();

export const categoryLabel = (c: Category): string =>
  c.difficulty ? `${c.name} — ${c.difficulty}` : c.name;
