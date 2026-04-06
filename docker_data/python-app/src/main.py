import tkinter as tk

def main():
    # メインウィンドウの作成
    root = tk.Tk()
    root.title("Python GUI App in Docker")
    root.geometry("300x200")

    # ラベルの追加
    label = tk.Label(root, text="Hello, Docker GUI!", pady=20)
    label.pack()

    # 閉じるボタン
    button = tk.Button(root, text="Close", command=root.destroy)
    button.pack()

    # 画面を表示し続ける
    root.mainloop()

if __name__ == "__main__":
    main()