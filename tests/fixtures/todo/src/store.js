// In-memory todo store. Ids are positive integers, assigned in order.
export function createStore() {
  const todos = new Map();
  let nextId = 1;
  return {
    add(title) {
      const todo = { id: nextId++, title, done: false };
      todos.set(todo.id, todo);
      return { ...todo };
    },
    list() {
      return [...todos.values()].map((todo) => ({ ...todo }));
    },
    get(id) {
      const todo = todos.get(id);
      return todo ? { ...todo } : undefined;
    },
  };
}
