// SAMPLE CONTENT for building and testing the UI.
//
// Chapter 1 (Arrays) is complete: 2 lessons x 6 questions (4 MCQ + 2 coding).
// Chapters 2-6 are PLACEHOLDERS with 2 questions per lesson (1 MCQ + 1 coding)
// so the whole path can be clicked through. Person C replaces all of this
// with the real question bank in Supabase (plan §7, Person C).

import 'package:bytestreak/data/repositories.dart';
import 'package:bytestreak/domain/game_rules.dart';
import 'package:bytestreak/domain/models.dart';

class FakeContentRepository implements ContentRepository {
  @override
  Future<CoursePath> loadPath() async => buildSamplePath();
}

McqQuestion _mcq(
  String id,
  String topic,
  Difficulty difficulty,
  String prompt,
  List<String> options,
  int correct, {
  required List<String> hints,
  required String why,
}) {
  return McqQuestion(
    id: id,
    difficulty: difficulty,
    prompt: prompt,
    options: options,
    correctIndex: correct,
    hints: hints,
    solution: why,
    xpReward: GameRules.defaultXpReward(QuestionType.mcq, difficulty),
    topic: topic,
  );
}

CodingQuestion _code(
  String id,
  String topic,
  Difficulty difficulty,
  String title, {
  required String description,
  required List<CodeExample> examples,
  required List<String> constraints,
  required String starter,
  required List<TestCase> tests,
  required List<String> hints,
  required String solution,
}) {
  return CodingQuestion(
    id: id,
    difficulty: difficulty,
    prompt: title,
    description: description,
    examples: examples,
    constraints: constraints,
    starterCode: {'python': starter},
    testCases: tests,
    hints: hints,
    solution: solution,
    xpReward: GameRules.defaultXpReward(QuestionType.coding, difficulty),
    topic: topic,
  );
}

/// Quiz = up to 10 questions from the chapter's lessons, mixed: MCQs and
/// coding questions interleaved so both types always appear.
Lesson _quizFor(String chapterId, String title, List<Lesson> lessons) {
  final all = [for (final l in lessons) ...l.questions];
  final mcqs = all.whereType<McqQuestion>().toList();
  final coding = all.whereType<CodingQuestion>().toList();
  final picked = <Question>[];
  var m = 0, c = 0;
  while (picked.length < GameRules.quizSize && (m < mcqs.length || c < coding.length)) {
    for (var i = 0; i < 3 && m < mcqs.length && picked.length < GameRules.quizSize; i++) {
      picked.add(mcqs[m++]);
    }
    if (c < coding.length && picked.length < GameRules.quizSize) picked.add(coding[c++]);
  }
  return Lesson(id: '$chapterId-quiz', chapterId: chapterId, title: '$title quiz', questions: picked, isQuiz: true);
}

Chapter _chapter(int number, String id, String title, String summary, List<Lesson> lessons) {
  return Chapter(
    id: id,
    number: number,
    title: title,
    summary: summary,
    lessons: lessons,
    quiz: _quizFor(id, title, lessons),
  );
}

CoursePath buildSamplePath() {
  const arrays = 'Arrays';
  final ch1 = _chapter(1, 'arrays', arrays, 'Indexing, scanning, prefix sums and in-place updates.', [
    Lesson(
      id: 'arrays-1',
      chapterId: 'arrays',
      title: 'Array basics',
      questions: [
        _mcq(
          'arr-1-1',
          arrays,
          Difficulty.easy,
          'What is the time complexity of reading nums[i] from an array?',
          ['O(1)', 'O(log n)', 'O(n)', 'O(n²)'],
          0,
          hints: [
            'Arrays store elements next to each other in memory.',
            'Knowing i, the computer can calculate the exact memory address directly.',
          ],
          why: 'The address of nums[i] is start + i × element size, so it takes the same time for any i.',
        ),
        _mcq(
          'arr-1-2',
          arrays,
          Difficulty.easy,
          'Which operation on a Python list is O(n) in the worst case?',
          ['Appending to the end', 'Reading by index', 'Inserting at index 0', 'Calling len()'],
          2,
          hints: [
            'Think about what happens to the elements that are already in the list.',
            'Inserting at the front means every existing element has to shift one place.',
          ],
          why: 'Inserting at index 0 shifts all n existing elements one position to the right.',
        ),
        _mcq(
          'arr-1-3',
          arrays,
          Difficulty.medium,
          'What is the best possible time to find the maximum of an unsorted array of n numbers?',
          ['O(1)', 'O(log n)', 'O(n)', 'O(n log n)'],
          2,
          hints: [
            'Could the maximum be hiding in a position you never looked at?',
            'Every element has to be inspected at least once.',
          ],
          why: 'Any element could be the maximum, so all n must be read: O(n), and one pass achieves it.',
        ),
        _mcq(
          'arr-1-4',
          arrays,
          Difficulty.medium,
          'After a = [3, 1, 2] and b = a, you run b.append(4). What is a?',
          ['[3, 1, 2]', '[3, 1, 2, 4]', '[4, 3, 1, 2]', 'An error'],
          1,
          hints: ['Does b = a copy the list, or give it a second name?', 'Both names point to the same list object.'],
          why: 'b = a makes b refer to the same list, so appending through b changes a too.',
        ),
        _code(
          'arr-1-5',
          arrays,
          Difficulty.easy,
          'Find the Maximum',
          description:
              'Given a non-empty list of integers nums, return the largest value. '
              'Do it in one pass without using the built-in max().',
          examples: const [
            CodeExample(input: 'nums = [3, 7, 2]', output: '7'),
            CodeExample(input: 'nums = [-5, -1, -9]', output: '-1', explanation: 'All negative: -1 is the largest.'),
          ],
          constraints: const ['1 ≤ len(nums) ≤ 10⁵', '-10⁹ ≤ nums[i] ≤ 10⁹'],
          starter: 'def find_max(nums):\n    best = nums[0]\n    # TODO: scan the rest of the list\n    return best\n',
          tests: const [
            TestCase(input: 'nums = [3, 7, 2]', expected: '7'),
            TestCase(input: 'nums = [-5, -1, -9]', expected: '-1'),
            TestCase(input: 'nums = [4]', expected: '4', hidden: true),
          ],
          hints: [
            'Keep a variable holding the largest value seen so far.',
            'Start it at nums[0], then compare it with every other element.',
          ],
          solution:
              'def find_max(nums):\n    best = nums[0]\n    for x in nums[1:]:\n        if x > best:\n            best = x\n    return best\n',
        ),
        _code(
          'arr-1-6',
          arrays,
          Difficulty.medium,
          'Running Sum',
          description: 'Return a list where element i is the sum of nums[0] through nums[i].',
          examples: const [
            CodeExample(input: 'nums = [1, 2, 3, 4]', output: '[1, 3, 6, 10]'),
            CodeExample(input: 'nums = [5]', output: '[5]'),
          ],
          constraints: const ['1 ≤ len(nums) ≤ 1000', '-10⁶ ≤ nums[i] ≤ 10⁶'],
          starter: 'def running_sum(nums):\n    result = []\n    # TODO: keep a running total\n    return result\n',
          tests: const [
            TestCase(input: 'nums = [1, 2, 3, 4]', expected: '[1, 3, 6, 10]'),
            TestCase(input: 'nums = [3, -1, 2]', expected: '[3, 2, 4]'),
            TestCase(input: 'nums = [0, 0]', expected: '[0, 0]', hidden: true),
          ],
          hints: [
            'You never need to re-add earlier numbers.',
            'Keep one total; add each number to it and append the total.',
          ],
          solution:
              'def running_sum(nums):\n    total = 0\n    result = []\n    for x in nums:\n        total += x\n        result.append(total)\n    return result\n',
        ),
      ],
    ),
    Lesson(
      id: 'arrays-2',
      chapterId: 'arrays',
      title: 'Prefix sums',
      questions: [
        _mcq(
          'arr-2-1',
          arrays,
          Difficulty.medium,
          'P is a prefix-sum array where P[i] is the sum of nums[0..i-1]. Which gives the sum of nums[l..r] inclusive?',
          ['P[r + 1] - P[l]', 'P[r] - P[l]', 'P[r] - P[l - 1]', 'P[r + 1] - P[l + 1]'],
          0,
          hints: ['P[r + 1] covers everything up to and including r.', 'Subtract the part before l.'],
          why: 'P[r + 1] is the sum of nums[0..r] and P[l] is the sum of nums[0..l-1]; the difference is nums[l..r].',
        ),
        _mcq(
          'arr-2-2',
          arrays,
          Difficulty.easy,
          'How long does it take to build a prefix-sum array for n numbers?',
          ['O(1)', 'O(log n)', 'O(n)', 'O(n²)'],
          2,
          hints: ['Each prefix extends the previous one by a single number.'],
          why: 'P[i + 1] = P[i] + nums[i]: one addition per element, so O(n).',
        ),
        _mcq(
          'arr-2-3',
          arrays,
          Difficulty.medium,
          'Which approach reverses an array in place using O(1) extra space?',
          [
            'Swap pairs from both ends, moving inward',
            'Build a reversed copy',
            'Sort it in descending order',
            'Push everything onto a stack and pop it back',
          ],
          0,
          hints: ['In place means no second array.', 'The first and last elements need to trade places.'],
          why: 'Swapping nums[i] and nums[n-1-i] for the first half reverses the array with only a temp variable.',
        ),
        _mcq(
          'arr-2-4',
          arrays,
          Difficulty.hard,
          'You must answer 10⁵ range-sum queries on a fixed array of 10⁵ numbers. Which is fastest overall?',
          [
            'Loop over the range for each query',
            'Build prefix sums once, then answer each query in O(1)',
            'Sort the array first',
            'Binary-search each query',
          ],
          1,
          hints: ['Looping per query costs up to 10⁵ × 10⁵ steps.', 'Do some work once so each query becomes cheap.'],
          why: 'Prefix sums cost O(n) once; each query is then one subtraction, O(n + q) in total.',
        ),
        _code(
          'arr-2-5',
          arrays,
          Difficulty.medium,
          'Range Sums',
          description:
              'Given nums and a list of queries [l, r], return a list with the sum of nums[l..r] '
              '(inclusive) for each query. Aim for O(n + q).',
          examples: const [CodeExample(input: 'nums = [2, 4, 1, 3], queries = [[0, 1], [1, 3]]', output: '[6, 8]')],
          constraints: const ['1 ≤ len(nums), len(queries) ≤ 10⁵', '0 ≤ l ≤ r < len(nums)'],
          starter:
              'def range_sums(nums, queries):\n    # TODO: build prefix sums, then answer each query\n    return []\n',
          tests: const [
            TestCase(input: 'nums = [2, 4, 1, 3], queries = [[0, 1], [1, 3]]', expected: '[6, 8]'),
            TestCase(input: 'nums = [5], queries = [[0, 0]]', expected: '[5]'),
            TestCase(input: 'nums = [1, 1, 1, 1], queries = [[0, 3], [2, 2]]', expected: '[4, 1]', hidden: true),
          ],
          hints: ['Build P with len(nums) + 1 entries, starting at 0.', 'Each answer is P[r + 1] - P[l].'],
          solution:
              'def range_sums(nums, queries):\n    p = [0]\n    for x in nums:\n        p.append(p[-1] + x)\n    return [p[r + 1] - p[l] for l, r in queries]\n',
        ),
        _code(
          'arr-2-6',
          arrays,
          Difficulty.medium,
          'Reverse In Place',
          description: 'Reverse the list nums in place, using O(1) extra space, and return it.',
          examples: const [CodeExample(input: 'nums = [1, 2, 3, 4]', output: '[4, 3, 2, 1]')],
          constraints: const ['0 ≤ len(nums) ≤ 10⁵', 'Do not use nums[::-1] or reversed()'],
          starter:
              'def reverse_in_place(nums):\n    left, right = 0, len(nums) - 1\n    # TODO: swap and move inward\n    return nums\n',
          tests: const [
            TestCase(input: 'nums = [1, 2, 3, 4]', expected: '[4, 3, 2, 1]'),
            TestCase(input: 'nums = [7]', expected: '[7]'),
            TestCase(input: 'nums = []', expected: '[]', hidden: true),
          ],
          hints: [
            'Use two pointers: one at each end.',
            'Swap, then move left forward and right backward until they meet.',
          ],
          solution:
              'def reverse_in_place(nums):\n    left, right = 0, len(nums) - 1\n    while left < right:\n        nums[left], nums[right] = nums[right], nums[left]\n        left += 1\n        right -= 1\n    return nums\n',
        ),
      ],
    ),
  ]);

  // ---- Placeholder chapters (Person C replaces these) -----------------------

  Lesson placeholder(String chapterId, int n, String title, String topic, McqQuestion mcq, CodingQuestion code) =>
      Lesson(id: '$chapterId-$n', chapterId: chapterId, title: title, questions: [mcq, code]);

  const hashing = 'Hashing';
  final ch2 = _chapter(2, 'hashing', hashing, 'Hash maps and sets for O(1) lookups.', [
    placeholder(
      'hashing',
      1,
      'Hash maps',
      hashing,
      _mcq(
        'hash-1-1',
        hashing,
        Difficulty.easy,
        'What is the average time to look up a key in a hash map?',
        ['O(1)', 'O(log n)', 'O(n)', 'O(n log n)'],
        0,
        hints: ['The key is hashed straight to a bucket.'],
        why: 'Hashing jumps directly to the right bucket, so lookups are O(1) on average.',
      ),
      _code(
        'hash-1-2',
        hashing,
        Difficulty.medium,
        'Pair With Target Sum',
        description:
            'Return the indices [i, j] (i < j) of two numbers in nums that add up to target. '
            'Exactly one answer exists.',
        examples: const [CodeExample(input: 'nums = [2, 7, 11, 15], target = 9', output: '[0, 1]')],
        constraints: const ['2 ≤ len(nums) ≤ 10⁴'],
        starter: 'def pair_sum(nums, target):\n    seen = {}\n    # TODO\n    return []\n',
        tests: const [
          TestCase(input: 'nums = [2, 7, 11, 15], target = 9', expected: '[0, 1]'),
          TestCase(input: 'nums = [3, 2, 4], target = 6', expected: '[1, 2]'),
        ],
        hints: ['For each number, what partner do you need?', 'Store each value\'s index in a dict as you go.'],
        solution:
            'def pair_sum(nums, target):\n    seen = {}\n    for i, x in enumerate(nums):\n        if target - x in seen:\n            return [seen[target - x], i]\n        seen[x] = i\n    return []\n',
      ),
    ),
    placeholder(
      'hashing',
      2,
      'Counting',
      hashing,
      _mcq(
        'hash-2-1',
        hashing,
        Difficulty.easy,
        'Which structure best answers "have I seen this value before?"',
        ['A set', 'A sorted list', 'A stack', 'A queue'],
        0,
        hints: ['You only need membership, not order.'],
        why: 'A set gives O(1) average membership checks.',
      ),
      _code(
        'hash-2-2',
        hashing,
        Difficulty.easy,
        'First Repeat',
        description: 'Return the first value in nums that appears for a second time, or -1 if none repeats.',
        examples: const [CodeExample(input: 'nums = [4, 1, 3, 1, 4]', output: '1')],
        constraints: const ['1 ≤ len(nums) ≤ 10⁵'],
        starter: 'def first_repeat(nums):\n    # TODO\n    return -1\n',
        tests: const [
          TestCase(input: 'nums = [4, 1, 3, 1, 4]', expected: '1'),
          TestCase(input: 'nums = [1, 2, 3]', expected: '-1'),
        ],
        hints: ['Walk left to right, remembering what you have seen.'],
        solution:
            'def first_repeat(nums):\n    seen = set()\n    for x in nums:\n        if x in seen:\n            return x\n        seen.add(x)\n    return -1\n',
      ),
    ),
  ]);

  const pointers = 'Two Pointers';
  final ch3 = _chapter(3, 'two-pointers', pointers, 'Opposite-end and fast/slow pointer patterns.', [
    placeholder(
      'two-pointers',
      1,
      'Opposite ends',
      pointers,
      _mcq(
        'tp-1-1',
        pointers,
        Difficulty.easy,
        'What is the time complexity of the two-pointer approach for finding a pair that sums to a target in a sorted array?',
        ['O(n log n)', 'O(n)', 'O(n²)', 'O(log n)'],
        1,
        hints: ['Each step moves one pointer inward.'],
        why: 'The pointers only move towards each other, so together they take at most n steps.',
      ),
      _code(
        'tp-1-2',
        pointers,
        Difficulty.easy,
        'Is Palindrome',
        description: 'Return True if the string s reads the same forwards and backwards.',
        examples: const [CodeExample(input: 's = "racecar"', output: 'True')],
        constraints: const ['0 ≤ len(s) ≤ 10⁵'],
        starter: 'def is_palindrome(s):\n    # TODO: compare from both ends\n    return False\n',
        tests: const [
          TestCase(input: 's = "racecar"', expected: 'True'),
          TestCase(input: 's = "abca"', expected: 'False'),
        ],
        hints: ['Compare s[left] and s[right], then move both inward.'],
        solution:
            'def is_palindrome(s):\n    l, r = 0, len(s) - 1\n    while l < r:\n        if s[l] != s[r]:\n            return False\n        l += 1\n        r -= 1\n    return True\n',
      ),
    ),
    placeholder(
      'two-pointers',
      2,
      'Fast & slow',
      pointers,
      _mcq(
        'tp-2-1',
        pointers,
        Difficulty.medium,
        'On a linked list, fast and slow pointers are most often used to…',
        ['Detect a cycle', 'Sort the list', 'Reverse the list', 'Count duplicates'],
        0,
        hints: ['If there is a loop, the fast pointer laps the slow one.'],
        why: 'In a cycle the fast pointer eventually meets the slow one (Floyd\'s algorithm).',
      ),
      _code(
        'tp-2-2',
        pointers,
        Difficulty.medium,
        'Container With Most Water',
        description:
            'height[i] is the height of a vertical line at x = i. Pick two lines that, with the '
            'x-axis, hold the most water. Return that amount.',
        examples: const [
          CodeExample(
            input: 'height = [1, 8, 6, 2, 5, 4, 8, 3, 7]',
            output: '49',
            explanation: 'Lines at index 1 and 8 hold 7 × 7 = 49.',
          ),
        ],
        constraints: const ['2 ≤ len(height) ≤ 10⁵', '0 ≤ height[i] ≤ 10⁴'],
        starter:
            'def max_area(height):\n    left, right = 0, len(height) - 1\n    best = 0\n    while left < right:\n        # TODO: compute the area and move the shorter line\n        pass\n    return best\n',
        tests: const [
          TestCase(input: 'height = [1, 8, 6, 2, 5, 4, 8, 3, 7]', expected: '49'),
          TestCase(input: 'height = [1, 1]', expected: '1'),
          TestCase(input: 'height = [4, 3, 2, 1, 4]', expected: '16', hidden: true),
        ],
        hints: [
          'Start with the widest possible container: one pointer at each end.',
          'Moving the taller line inward can never increase the area. Why?',
        ],
        solution:
            'def max_area(height):\n    left, right = 0, len(height) - 1\n    best = 0\n    while left < right:\n        h = min(height[left], height[right])\n        best = max(best, h * (right - left))\n        if height[left] < height[right]:\n            left += 1\n        else:\n            right -= 1\n    return best\n',
      ),
    ),
  ]);

  const trees = 'Trees';
  final ch4 = _chapter(4, 'trees', trees, 'Traversals and recursion on binary trees.', [
    placeholder(
      'trees',
      1,
      'Traversal',
      trees,
      _mcq(
        'tree-1-1',
        trees,
        Difficulty.easy,
        'An in-order traversal of a binary search tree visits values in…',
        ['Sorted order', 'Reverse insertion order', 'Level order', 'Random order'],
        0,
        hints: ['In-order = left, node, right.'],
        why: 'In a BST everything left is smaller and everything right is larger, so left-node-right is sorted.',
      ),
      _code(
        'tree-1-2',
        trees,
        Difficulty.easy,
        'Tree Height',
        description:
            'Given the root of a binary tree, return its maximum depth (nodes on the longest root-to-leaf path).',
        examples: const [CodeExample(input: 'root = [3, 9, 20, None, None, 15, 7]', output: '3')],
        constraints: const ['0 ≤ number of nodes ≤ 10⁴'],
        starter: 'def max_depth(root):\n    # TODO: depth of an empty tree is 0\n    return 0\n',
        tests: const [
          TestCase(input: 'root = [3, 9, 20, None, None, 15, 7]', expected: '3'),
          TestCase(input: 'root = []', expected: '0'),
        ],
        hints: ['Depth = 1 + the deeper of the two subtrees.'],
        solution:
            'def max_depth(root):\n    if root is None:\n        return 0\n    return 1 + max(max_depth(root.left), max_depth(root.right))\n',
      ),
    ),
    placeholder(
      'trees',
      2,
      'Recursion on trees',
      trees,
      _mcq(
        'tree-2-1',
        trees,
        Difficulty.easy,
        'The base case of most recursive tree functions is…',
        ['An empty (None) node', 'The root', 'The largest value', 'A node with two children'],
        0,
        hints: ['Where does the recursion stop?'],
        why: 'Recursion bottoms out at an empty subtree, which has a known answer (usually 0 or None).',
      ),
      _code(
        'tree-2-2',
        trees,
        Difficulty.medium,
        'Count Leaves',
        description: 'Return the number of leaf nodes (nodes with no children) in the tree.',
        examples: const [CodeExample(input: 'root = [1, 2, 3, 4]', output: '2')],
        constraints: const ['0 ≤ number of nodes ≤ 10⁴'],
        starter: 'def count_leaves(root):\n    # TODO\n    return 0\n',
        tests: const [
          TestCase(input: 'root = [1, 2, 3, 4]', expected: '2'),
          TestCase(input: 'root = [1]', expected: '1'),
        ],
        hints: ['A node with no left and no right child is a leaf.'],
        solution:
            'def count_leaves(root):\n    if root is None:\n        return 0\n    if root.left is None and root.right is None:\n        return 1\n    return count_leaves(root.left) + count_leaves(root.right)\n',
      ),
    ),
  ]);

  const graphs = 'Graphs';
  final ch5 = _chapter(5, 'graphs', graphs, 'BFS, DFS and connected components.', [
    placeholder(
      'graphs',
      1,
      'BFS & DFS',
      graphs,
      _mcq(
        'graph-1-1',
        graphs,
        Difficulty.medium,
        'On an unweighted graph, breadth-first search finds…',
        ['The shortest path in number of edges', 'The longest path', 'A minimum spanning tree', 'All cycles'],
        0,
        hints: ['BFS explores in layers of distance 1, 2, 3…'],
        why: 'BFS visits nodes in order of distance, so the first time it reaches a node is via a shortest path.',
      ),
      _code(
        'graph-1-2',
        graphs,
        Difficulty.medium,
        'Count Islands',
        description:
            'grid is a 2D list of "1" (land) and "0" (water). Return the number of islands '
            '(land connected up, down, left or right).',
        examples: const [CodeExample(input: 'grid = [["1","1","0"],["0","1","0"],["0","0","1"]]', output: '2')],
        constraints: const ['1 ≤ rows, cols ≤ 300'],
        starter: 'def count_islands(grid):\n    # TODO: flood-fill each new piece of land\n    return 0\n',
        tests: const [
          TestCase(input: 'grid = [["1","1","0"],["0","1","0"],["0","0","1"]]', expected: '2'),
          TestCase(input: 'grid = [["0"]]', expected: '0'),
        ],
        hints: ['Each time you find unvisited land, that is a new island.', 'Mark its whole island visited with DFS.'],
        solution:
            'def count_islands(grid):\n    rows, cols = len(grid), len(grid[0])\n    def sink(r, c):\n        if 0 <= r < rows and 0 <= c < cols and grid[r][c] == "1":\n            grid[r][c] = "0"\n            for dr, dc in ((1,0),(-1,0),(0,1),(0,-1)):\n                sink(r + dr, c + dc)\n    count = 0\n    for r in range(rows):\n        for c in range(cols):\n            if grid[r][c] == "1":\n                count += 1\n                sink(r, c)\n    return count\n',
      ),
    ),
    placeholder(
      'graphs',
      2,
      'Connected components',
      graphs,
      _mcq(
        'graph-2-1',
        graphs,
        Difficulty.easy,
        'Why does graph traversal keep a visited set?',
        ['To avoid looping forever and revisiting nodes', 'To sort the nodes', 'To find the root', 'To count edges'],
        0,
        hints: ['Graphs can contain cycles.'],
        why: 'Without it, a cycle would send the traversal round and round.',
      ),
      _code(
        'graph-2-2',
        graphs,
        Difficulty.medium,
        'Count Components',
        description:
            'Given n nodes labelled 0..n-1 and a list of undirected edges, return the number of connected components.',
        examples: const [CodeExample(input: 'n = 5, edges = [[0, 1], [1, 2], [3, 4]]', output: '2')],
        constraints: const ['1 ≤ n ≤ 2000'],
        starter: 'def count_components(n, edges):\n    # TODO\n    return 0\n',
        tests: const [
          TestCase(input: 'n = 5, edges = [[0, 1], [1, 2], [3, 4]]', expected: '2'),
          TestCase(input: 'n = 3, edges = []', expected: '3'),
        ],
        hints: ['Build an adjacency list, then DFS from every unvisited node.'],
        solution:
            'def count_components(n, edges):\n    adj = [[] for _ in range(n)]\n    for a, b in edges:\n        adj[a].append(b)\n        adj[b].append(a)\n    seen = set()\n    def dfs(u):\n        seen.add(u)\n        for v in adj[u]:\n            if v not in seen:\n                dfs(v)\n    count = 0\n    for u in range(n):\n        if u not in seen:\n            count += 1\n            dfs(u)\n    return count\n',
      ),
    ),
  ]);

  const dp = 'Dynamic Programming';
  final ch6 = _chapter(6, 'dp', dp, 'Memoisation and bottom-up tables.', [
    placeholder(
      'dp',
      1,
      'Memoisation',
      dp,
      _mcq(
        'dp-1-1',
        dp,
        Difficulty.medium,
        'Memoisation speeds up recursion by…',
        [
          'Storing answers to subproblems so they are computed once',
          'Running calls in parallel',
          'Sorting the input',
          'Removing the base case',
        ],
        0,
        hints: ['Naive recursive Fibonacci recomputes the same values many times.'],
        why: 'Caching each subproblem\'s answer turns exponential recursion into one computation per subproblem.',
      ),
      _code(
        'dp-1-2',
        dp,
        Difficulty.easy,
        'Climbing Stairs',
        description: 'You can climb 1 or 2 steps at a time. In how many distinct ways can you reach step n?',
        examples: const [CodeExample(input: 'n = 3', output: '3', explanation: '1+1+1, 1+2, 2+1')],
        constraints: const ['1 ≤ n ≤ 45'],
        starter: 'def climb(n):\n    # TODO\n    return 0\n',
        tests: const [
          TestCase(input: 'n = 3', expected: '3'),
          TestCase(input: 'n = 5', expected: '8'),
        ],
        hints: ['ways(n) = ways(n - 1) + ways(n - 2).'],
        solution: 'def climb(n):\n    a, b = 1, 1\n    for _ in range(n):\n        a, b = b, a + b\n    return a\n',
      ),
    ),
    placeholder(
      'dp',
      2,
      'Bottom-up tables',
      dp,
      _mcq(
        'dp-2-1',
        dp,
        Difficulty.easy,
        'Computing the nth Fibonacci number bottom-up takes…',
        ['O(n) time', 'O(2ⁿ) time', 'O(n²) time', 'O(1) time'],
        0,
        hints: ['Each value is computed once from the previous two.'],
        why: 'A single loop from 2 to n, with O(1) work per step.',
      ),
      _code(
        'dp-2-2',
        dp,
        Difficulty.medium,
        'Max Non-Adjacent Sum',
        description: 'Return the largest sum of elements of nums with no two chosen elements next to each other.',
        examples: const [CodeExample(input: 'nums = [2, 7, 9, 3, 1]', output: '12', explanation: '2 + 9 + 1')],
        constraints: const ['1 ≤ len(nums) ≤ 100', '0 ≤ nums[i] ≤ 400'],
        starter: 'def max_non_adjacent(nums):\n    # TODO\n    return 0\n',
        tests: const [
          TestCase(input: 'nums = [2, 7, 9, 3, 1]', expected: '12'),
          TestCase(input: 'nums = [5]', expected: '5'),
        ],
        hints: ['At each element: take it (plus best two back) or skip it.'],
        solution:
            'def max_non_adjacent(nums):\n    take, skip = 0, 0\n    for x in nums:\n        take, skip = skip + x, max(take, skip)\n    return max(take, skip)\n',
      ),
    ),
  ]);

  return CoursePath(title: 'LeetCode Mastery', chapters: [ch1, ch2, ch3, ch4, ch5, ch6]);
}
