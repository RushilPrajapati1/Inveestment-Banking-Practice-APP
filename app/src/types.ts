export type Difficulty = "Basic" | "Advanced" | null;

export interface Question {
  id: string;
  n: number;
  category: string;
  group: string;
  difficulty: Difficulty;
  question: string;
  answer: string;
  source_line: number;
}

export interface Category {
  name: string;
  group: string;
  difficulty: Difficulty;
  slug: string;
  count: number;
  questions: Question[];
}

export interface Dataset {
  categories: Category[];
}
