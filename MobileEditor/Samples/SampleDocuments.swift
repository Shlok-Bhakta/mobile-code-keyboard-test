import Foundation

enum SampleDocuments {
    struct Sample {
        let title: String
        let text: String
    }

    static let rust = Sample(
        title: "Rust",
        text: """
        fn calculate_thing(value: i32) -> i32 {
            let doubled = value * 2;
            if doubled > 10 {
                println!("large value: {}", doubled);
            }
            doubled
        }

        fn main() {
            let result = calculate_thing(7);
            println!("result = {}", result);
        }

        """
    )

    static let typeScript = Sample(
        title: "TypeScript",
        text: """
        type User = {
          id: string;
          name: string;
          active?: boolean;
        };

        export function greet(user: User): string {
          const label = user.active === false ? "offline" : "online";
          return `${user.name} (${label})`;
        }

        const users: User[] = [
          { id: "1", name: "ada", active: true },
          { id: "2", name: "grace" },
        ];

        for (const user of users) {
          console.log(greet(user));
        }

        """
    )

    static let python = Sample(
        title: "Python",
        text: """
        def calculate_thing(value: int) -> int:
            doubled = value * 2
            if doubled > 10:
                print(f"large value: {doubled}")
            return doubled


        def main() -> None:
            result = calculate_thing(7)
            print(f"result = {result}")


        if __name__ == "__main__":
            main()

        """
    )

    static let markdown = Sample(
        title: "Markdown",
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

    static let all: [Sample] = [rust, typeScript, python, markdown]
}
