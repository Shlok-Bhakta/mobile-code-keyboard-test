import Foundation

enum SampleDocuments {
    struct Sample {
        let title: String
        let language: RunLanguage
        let text: String
    }

    static let python = Sample(
        title: "Python",
        language: .python,
        text: """
# FizzBuzz: fill in fizzbuzz(n) so the tests pass, then hit Run.
# Multiples of 3 -> "Fizz", of 5 -> "Buzz", of both -> "FizzBuzz",
# otherwise the number itself.

def fizzbuzz(n):
    out = []
    for i in range(1, n + 1):
        out.append(str(i))  # TODO: replace me
    return out


def _check():
    want = ["1", "2", "Fizz", "4", "Buzz", "Fizz", "7", "8", "Fizz",
            "Buzz", "11", "Fizz", "13", "14", "FizzBuzz"]
    got = fizzbuzz(15)
    assert got == want, f"first 15 wrong:\\n got {got}\\nwant {want}"
    assert fizzbuzz(1) == ["1"], "fizzbuzz(1) should be ['1']"
    assert fizzbuzz(0) == [], "fizzbuzz(0) should be []"
    print("All tests passed.")


if __name__ == "__main__":
    _check()

"""
    )

    static let typeScript = Sample(
        title: "TypeScript",
        language: .typescript,
        text: """
// FizzBuzz: fill in fizzbuzz(n) so the tests would pass.
// Multiples of 3 -> "Fizz", of 5 -> "Buzz", of both -> "FizzBuzz",
// otherwise the number itself.
// (TypeScript doesn't run in this build yet — Python and Rust do.)

function fizzbuzz(n: number): string[] {
  const out: string[] = [];
  for (let i = 1; i <= n; i++) {
    out.push(String(i)); // TODO: replace me
  }
  return out;
}

function check(): void {
  const want = ["1", "2", "Fizz", "4", "Buzz", "Fizz", "7", "8",
    "Fizz", "Buzz", "11", "Fizz", "13", "14", "FizzBuzz"];
  const got = fizzbuzz(15);
  if (JSON.stringify(got) !== JSON.stringify(want)) {
    console.log("FAIL: first 15 wrong");
    console.log(" got " + JSON.stringify(got));
    console.log("want " + JSON.stringify(want));
    throw new Error("tests failed");
  }
  if (JSON.stringify(fizzbuzz(1)) !== '["1"]') {
    throw new Error("fizzbuzz(1) should be ['1']");
  }
  if (fizzbuzz(0).length !== 0) {
    throw new Error("fizzbuzz(0) should be []");
  }
  console.log("All tests passed.");
}

check();
"""
    )

    static let rust = Sample(
        title: "Rust",
        language: .rust,
        text: """
// FizzBuzz: fill in fizzbuzz(n) so the tests pass, then hit Run.
// Multiples of 3 -> "Fizz", of 5 -> "Buzz", of both -> "FizzBuzz",
// otherwise the number itself.

fn fizzbuzz(n: u32) -> Vec<String> {
    let mut out = Vec::new();
    for i in 1..=n {
        out.push(i.to_string()); // TODO: replace me
    }
    out
}

fn main() {
    let want: Vec<String> = ["1", "2", "Fizz", "4", "Buzz", "Fizz", "7", "8",
        "Fizz", "Buzz", "11", "Fizz", "13", "14", "FizzBuzz"]
        .iter()
        .map(|s| s.to_string())
        .collect();
    let got = fizzbuzz(15);
    assert_eq!(got, want, "first 15 wrong");
    assert_eq!(fizzbuzz(1), vec!["1".to_string()]);
    assert!(fizzbuzz(0).is_empty(), "fizzbuzz(0) should be empty");
    println!("All tests passed.");
}
"""
    )

    static let markdown = Sample(
        title: "Markdown",
        language: .markdown,
        text: """
# Scratch notes

Edit this like a tiny README.

- tabs and spaces
- `inline code`
- [links](https://example.com)

```rust
fn main() {
    println!("hello");
}
```

Use NAV + SELECT to grab a whole list item, then wrap it with `()`.
"""
    )

    static let all: [Sample] = [python, typeScript, rust, markdown]
}
