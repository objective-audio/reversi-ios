/// コンピュータの処理に必要なデータ
struct Computer {
    let positions: [Position]
    let completion: (Position) -> Void
}
