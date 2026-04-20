import { defineCollection, z } from 'astro:content';

const diary = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string().min(1, 'title 不能为空'),
    date: z.coerce.date(),
    summary: z.string().min(1, 'summary 不能为空').max(220, 'summary 过长'),
    cover: z.string().optional(),
    tags: z.array(z.string()).default([]),
    draft: z.boolean().default(false)
  })
});

export const collections = {
  diary
};
