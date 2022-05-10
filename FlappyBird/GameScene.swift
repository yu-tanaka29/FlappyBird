//
//  GameScene.swift
//  FlappyBird
//
//  Created by 田中 勇輝 on 2022/04/21.
//

import SpriteKit

class GameScene: SKScene {
    
    // MARK: - Private
    var scrollNode: SKNode! // 定義
    var wallNode: SKNode! // 定義
    var bird:SKSpriteNode! // 定義
    var coinNode: SKNode! // 定義
    
    // 衝突判定カテゴリー ↓追加
    let birdCategory: UInt32 = 1 << 0       // 0...00001
    let groundCategory: UInt32 = 1 << 1     // 0...00010
    let wallCategory: UInt32 = 1 << 2       // 0...00100
    let scoreCategory: UInt32 = 1 << 3      // 0...01000
    let coinCategory: UInt32 = 1 << 4       // 0...10000
    
    // スコア用
    var score = 0
    var coinScore = 0
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    var coinScoreLabelNode:SKLabelNode!
    let userDefaults:UserDefaults = UserDefaults.standard
    
    // 再生データの作成.
    let mySoundAction: SKAction = SKAction.playSoundFileNamed("getCoin.mp3", waitForCompletion: true)
    
    // SKView上にシーンが表示されたときに呼ばれるメソッド
    override func didMove(to view: SKView) {
        // 重力を設定
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self
        
        // 背景色を設定
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        // スクロールするスプライトの親ノード
        self.scrollNode = SKNode()
        addChild(self.scrollNode)
        
        // 壁用のノード
        self.wallNode = SKNode()
        addChild(self.wallNode)
        
        // 壁用のノード
        self.coinNode = SKNode()
        addChild(self.coinNode)
        
        // 各種スプライトを生成する処理をメソッドに分割
        self.setUpGround()
        self.setUpCloud()
        self.setUpWall()
        self.setUpBird()
        self.setUpCoin()
        
        // スコア表示ラベルの設定
        self.setupScoreLabel()
    }
    
    // MARK: - Private Methods
    // 地面作成
    func setUpGround() {
        // 地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        
        // 必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
        
        // 元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
        
        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repearScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround,resetGround]))
        
        // groundのスプライトを配置する
        for i in 0 ..< needNumber {
            // テクスチャを指定してスプライトを作成する
            let sprite = SKSpriteNode(texture: groundTexture)
            
            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2 + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )
            
            // スプライトにアクションを設定する
            sprite.run(repearScrollGround)
            
            // スプライトに物理体を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            // 衝突のカテゴリー設定
            sprite.physicsBody?.categoryBitMask = self.groundCategory
            
            // 衝突の時に動かないように設定する
            sprite.physicsBody?.isDynamic = false
            
            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    // 空の作成
    func setUpCloud() {
        // 雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        // 必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20)
        
        // 元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        
        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud,resetCloud]))
        
        // スプライトを配置する
        for i in 0 ..< needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 // 一番後ろになるようにする
            
            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )
            
            // スプライトにアニメーションを設定する
            sprite.run(repeatScrollCloud)
            
            // スプライトを追加する
            self.scrollNode.addChild(sprite)
        }
    }
    
    // 壁の作成
    func setUpWall() {
        // 壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        // 移動する距離を計算
        let movingDistance = self.frame.size.width + wallTexture.size().width
        
        // 画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)
        
        // 自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall,removeWall])
        
        // 鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        // 鳥が通り抜ける隙間の大きさを鳥のサイズの4倍とする
        let slit_length = birdSize.height * 4
        
        // 隙間位置の上下の振れ幅を60ptとする
        let random_y_range: CGFloat = 60
        
        // 空の中央位置(y座標)を取得
        let groundSize = SKTexture(imageNamed: "ground").size()
        let sky_center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        
        // 空の中央位置を基準にして下側の壁の中央位置を取得
        let under_wall_center_y = sky_center_y - slit_length / 2 - wallTexture.size().height / 2
        
        // 壁を生成するアクションを作成
        let createWallAnimation = SKAction.run({
            // 壁をまとめるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            wall.zPosition = -50 // 雲より手前、地面より奥
            
            // 下側の壁の中央位置にランダム値を足して、下側の壁の表示位置を決定する
            let random_y = CGFloat.random(in: -random_y_range...random_y_range)
            let under_wall_y = under_wall_center_y + random_y
            
            // 下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            
            // 下側の壁に物理体を設定する
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            under.physicsBody?.isDynamic = false

            // 壁をまとめるノードに下側の壁を追加
            wall.addChild(under)
            
            // 上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            // 上側の壁に物理体を設定する
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            upper.physicsBody?.isDynamic = false

            // 壁をまとめるノードに上側の壁を追加
            wall.addChild(upper)
            
            // スコアカウント用の透明な壁を作成
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            // 透明な壁に物理体を設定する
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.isDynamic = false
            // 壁をまとめるノードに透明な壁を追加
            wall.addChild(scoreNode)
            
            // 壁をまとめるノードにアニメーションを設定
            wall.run(wallAnimation)
            
            // 壁を表示するノードに今回作成した壁を追加
            self.wallNode.addChild(wall)
        })
        
        // 次の壁作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)

        // 壁を作成->時間待ち->壁を作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))

        // // 壁を表示するノードに壁の作成を無限に繰り返すアクションを設定
        self.wallNode.run(repeatForeverAnimation)
    }
    
    // コインの生成
    func setUpCoin() {
        // コインのサイズ取得
        let coinSize = SKTexture(imageNamed: "coin").size()
        
        // 移動する距離を計算
        let movingDistance = self.frame.size.width + coinSize.width
        // 画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration: 6)
        // 自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let coinAnimation = SKAction.sequence([moveWall,removeWall])
        
        // コインを生成するアクションを作成
        let createCoinAnimation = SKAction.run({
            let coin = SKSpriteNode(imageNamed: "coin")
            coin.size = CGSize(width: 80, height: 80)
            
            let wallSize = SKTexture(imageNamed: "wall").size()
            // 空の中央位置(y座標)を取得
            let groundSize = SKTexture(imageNamed: "ground").size()
            let sky_center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
            // ランダム値を足し、コインを配置する高さをバラバラにする
            let random_y = CGFloat.random(in: -100...100)
            // スプライトを作成
            coin.position = CGPoint(x: self.frame.size.width + wallSize.width / 2 + 10, y: sky_center_y + random_y)
            
            // コインに物理体を設定する
            coin.physicsBody = SKPhysicsBody(circleOfRadius: coin.size.height / 2)
            coin.physicsBody?.categoryBitMask = self.coinCategory
            coin.physicsBody?.isDynamic = false
            
            coin.run(coinAnimation)
            self.coinNode.addChild(coin)
        })
        
        // 次のコイン作成までの時間待ちのアクションを作成
        let waitAnimation1 = SKAction.wait(forDuration: 3) // スタート時に遅らせるため
        let waitAnimation2 = SKAction.wait(forDuration: 1) // コインの設置間隔を開けるため

        // 時間待ち->コインを作成->時間待ち->コインを作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([waitAnimation1, createCoinAnimation, waitAnimation2]))

        // コインの作成を無限に繰り返すアクションを設定
        self.coinNode.run(repeatForeverAnimation)
    }
    
    // 鳥の生成
    func setUpBird() {
        // 鳥の画像を2種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear

        // 2種類のテクスチャを交互に変更するアニメーションを作成
        let texturesAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texturesAnimation)

        // スプライトを作成
        self.bird = SKSpriteNode(texture: birdTextureA)
        self.bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        
        // 物理体を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        
        // カテゴリー設定
        self.bird.physicsBody?.categoryBitMask = self.birdCategory // 1と0のビット
        // 当たった時に跳ね返る動作をする相手(壁と地面)を設定
        self.bird.physicsBody?.collisionBitMask = self.groundCategory | self.wallCategory
        // 衝突判定の対象となるカテゴリの指定
        self.bird.physicsBody?.contactTestBitMask = self.groundCategory | self.wallCategory | self.scoreCategory | self.coinCategory
        
        // 衝突した時に回転させない
        self.bird.physicsBody?.allowsRotation = false

        // アニメーションを設定
        self.bird.run(flap)

        // スプライトを追加する
        addChild(self.bird)
    }
    
    // 画面をタップした時に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.scrollNode.speed > 0 {
            // 鳥の速度をゼロにする
            self.bird.physicsBody?.velocity = CGVector.zero

            // 鳥に縦方向の力を与える
            self.bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        } else if self.bird.speed == 0 {
            self.restart()
        }
    }
    
    // リスタート処理
    func restart() {
        // スコアを0にする
        self.score = 0
        self.coinScore = 0
        self.scoreLabelNode.text = "Score:\(self.score)"
        self.coinScoreLabelNode.text = "Item Score:\(self.coinScore)"

        // 鳥を初期位置に戻し、壁と地面の両方に反発するように戻す
        self.bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        self.bird.physicsBody?.velocity = CGVector.zero
        self.bird.physicsBody?.collisionBitMask = self.groundCategory | self.wallCategory
        self.bird.zRotation = 0

        // 全ての壁を取り除く
        self.wallNode.removeAllChildren()
        
        // 全てのコインを取り除く
        self.coinNode.removeAllChildren()

        // 鳥の羽ばたきを戻す
        self.bird.speed = 1

        // スクロールを再開させる
        self.scrollNode.speed = 1
    }
    
    // スコア表示
    func setupScoreLabel() {
        // スコア表示を作成
        self.score = 0
        self.scoreLabelNode = SKLabelNode()
        self.scoreLabelNode.fontColor = UIColor.black
        self.scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        self.scoreLabelNode.zPosition = 100 // 一番手前に表示する
        self.scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        self.scoreLabelNode.text = "Score:\(self.score)"
        self.addChild(self.scoreLabelNode)

        // ベストスコア表示を作成
        let bestScore = self.userDefaults.integer(forKey: "BEST")
        self.bestScoreLabelNode = SKLabelNode()
        self.bestScoreLabelNode.fontColor = UIColor.black
        self.bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        self.bestScoreLabelNode.zPosition = 100 // 一番手前に表示する
        self.bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        self.bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(self.bestScoreLabelNode)
        
        // ベストスコア表示を作成
        self.coinScore = 0
        self.coinScoreLabelNode = SKLabelNode()
        self.coinScoreLabelNode.fontColor = UIColor.black
        self.coinScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        self.coinScoreLabelNode.zPosition = 100 // 一番手前に表示する
        self.coinScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        self.coinScoreLabelNode.text = "Item Score:\(self.coinScore)"
        self.addChild(self.coinScoreLabelNode)
    }
}

// MARK: - SKPhysicsContactDelegate
extension GameScene: SKPhysicsContactDelegate {
    // SKPhysicsContactDelegateのメソッド。衝突したときに呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        // ゲームオーバーのときは何もしない
        if self.scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & self.scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & self.scoreCategory) == self.scoreCategory {
            // スコアカウント用の透明な壁と衝突した
            print("ScoreUp")
            self.score += 1
            self.scoreLabelNode.text = "Score:\(self.score)"
            
            // ベストスコア更新か確認する --- ここから ---
            var bestScore = userDefaults.integer(forKey: "BEST")
            if self.score > bestScore {
                bestScore = self.score
                self.bestScoreLabelNode.text = "Best Score:\(bestScore)"
                self.userDefaults.set(bestScore, forKey: "BEST")
                self.userDefaults.synchronize()
            }
        } else if (contact.bodyA.categoryBitMask & self.coinCategory) == coinCategory || (contact.bodyB.categoryBitMask & self.coinCategory) == self.coinCategory {
            // コインと衝突した
            print("GetCoin")
            self.coinScore += 1
            self.coinScoreLabelNode.text = "Item Score:\(self.coinScore)"
            
            if contact.bodyA.categoryBitMask == self.coinCategory {
                contact.bodyA.node?.removeFromParent() // コイン削除
            } else {
                contact.bodyB.node?.removeFromParent() // コイン削除
            }
            // 再生アクション.
            self.run(mySoundAction);
        } else {
            // 壁か地面と衝突した
            print("GameOver")

            // スクロールを停止させる
            self.scrollNode.speed = 0

            // 衝突後は地面と反発するのみとする(リスタートするまで壁と反発させない)
            self.bird.physicsBody?.collisionBitMask = self.groundCategory

            // 衝突後1秒間、鳥をくるくる回転させる
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(self.bird.position.y) * 0.01, duration:1)
            self.bird.run(roll, completion:{
                self.bird.speed = 0
            })
        }
    }
}
