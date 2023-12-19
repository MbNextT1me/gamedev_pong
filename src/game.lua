--game.lua

Game = {}

function Game:new()
    local background = love.graphics.newImage("assets/img/bg.png")
    local gameMusic = love.audio.newSource("assets/sounds/s_game1.mp3", "stream")
    gameMusic:setVolume(0.5)
    local buttonTryAgain = love.graphics.newImage("assets/img/button_tryagain.png")
    local buttonContinue = love.graphics.newImage("assets/img/button_continue.png")
    local pauseOrLoseBg = love.graphics.newImage("assets/img/bg_gameover.png")

    local leftPaddleImage = love.graphics.newImage("assets/img/rocket_1.png")
    local rightPaddleImage = love.graphics.newImage("assets/img/rocket_2.png")

    local ballImage = love.graphics.newImage("assets/img/ball.png")
    
    local soundOnImage = love.graphics.newImage("assets/img/s_on.png")
    local soundOffImage = love.graphics.newImage("assets/img/s_off.png")

    local paddleHitSound = love.audio.newSource("assets/sounds/s_touch.wav", "static")
    local scoreSound = love.audio.newSource("assets/sounds/s_score.wav", "static")

    local game = {
        buttons = {},
        visibleButtons = {},
        background = background,
        pauseOrLoseBg = pauseOrLoseBg,
        gameMusic = gameMusic,
        paddleHitSound = paddleHitSound,
        scoreSound = scoreSound,
        soundOnImage = soundOnImage,
        soundOffImage = soundOffImage,
        soundIcon = soundOnImage,
        soundEnabled = true,
        screenWidth = screenWidth,
        screenHeight = screenHeight,
        scaleX = screenWidth / background:getWidth(),
        scaleY = screenHeight / background:getHeight(),
        scorePlayer1 = 0,
        scorePlayer2 = 0,
        flagPause = false,
        leftFlagStart = false,
        rightFlagStart = false,
        gameSpeed = 10,
        autoPaddleSpeed = 3,
        ballImage = ballImage,
        isGameOver = false,
        ballDeflectionByCenterPaddle = 0
    }

    local rand = math.random(game.gameSpeed/2, game.gameSpeed)

    -- Размеры ракеток на основе размеров изображений
    self.leftPaddle = {
        x = leftPaddleImage:getWidth()/2 * game.scaleX,
        y = game.screenHeight / 2 - leftPaddleImage:getHeight() / 2 * game.scaleY,
        width = leftPaddleImage:getWidth() * game.scaleX,
        height = leftPaddleImage:getHeight() * game.scaleY,
        image = leftPaddleImage,
        dy = 5
    }

    self.rightPaddle = {
        x = game.screenWidth - rightPaddleImage:getWidth()*1.5 * game.scaleX,
        y = game.screenHeight / 2 - rightPaddleImage:getHeight() / 2 * game.scaleY,
        width = rightPaddleImage:getWidth() * game.scaleX,
        height = rightPaddleImage:getHeight() * game.scaleY,
        image = rightPaddleImage,
        dy = 5
    }

    -- Размеры мяча
    self.ball = {
        x = game.screenWidth / 2,
        y = game.screenHeight / 2,
        size = ballImage:getWidth() / 2 * game.scaleX,
        prevDx = 0,
        prevDy = 0,
        dx = rand,
        dy = game.gameSpeed - rand,
        bg = ballImage,
        wickPx = 22
    }

    setmetatable(game, { __index = self })

    -- Добавление кнопок
    game:addButton("tryAgain", "button_tryagain.png", game.screenWidth/2, game.screenHeight/2, function() game:restartGame() end)
    game:addButton("continue", "button_continue.png", game.screenWidth/2 , game.screenHeight/2, function() game:togglePause() end)

    local soundButton = {
        name = "sound",
        image = soundOnImage,
        x = 10,
        y = 10,
        width = soundOnImage:getWidth(),
        height = soundOnImage:getHeight(),
        callback = function() game:toggleSound() end
    }

    table.insert(game.buttons, soundButton)

    return game
end

function Game:restartGame()
    -- Сброс счета
    self.scorePlayer1 = 0
    self.scorePlayer2 = 0

    self.isGameOver = false

    -- Возвращение мяча на центр
    self.ball.x = self.screenWidth / 2
    self.ball.y = self.screenHeight / 2

    -- Возвращение левой ракетки на начальное положение
    self.leftPaddle.y = self.screenHeight / 2 - self.leftPaddle.image:getHeight() / 2 * self.scaleY

    -- Возвращение правой ракетки на начальное положение
    self.rightPaddle.y = self.screenHeight / 2 - self.rightPaddle.image:getHeight() / 2 * self.scaleY
end

function Game:startMusic()
    -- Установка музыки на повторение и воспроизведение
    self.gameMusic:setLooping(true)
    love.audio.play(self.gameMusic)
end

function Game:stopMusic()
    self.gameMusic:setLooping(false)
    love.audio.stop(self.gameMusic)
end

function Game:toggleSound()
    self.soundEnabled = not self.soundEnabled

    if self.soundEnabled then
        self.soundIcon = self.soundOnImage
    else
        self.soundIcon = self.soundOffImage
    end
    for i, button in ipairs(self.buttons) do
        if button.name == "sound" then
            button.image = self.soundIcon
        end
    end
end

function Game:addButton(name, imageFile, x, y, callback)
    -- Создание изображения кнопки и добавление кнопки в массив
    local buttonImage = love.graphics.newImage("assets/img/" .. imageFile)
    local button = {
        name = name,
        image = buttonImage,
        x = x - buttonImage:getWidth()/2 * self.scaleX,
        y = y - buttonImage:getHeight() / 2 * self.scaleY,
        selected = false,
        callback = callback,
        buttonMargin = buttonImage:getHeight() * self.scaleY * 1.5
    }

    table.insert(self.buttons, button)
end

function Game:draw()
    love.graphics.setBackgroundColor(255, 255, 255)

    love.graphics.draw(self.background, 0, 0, 0, self.scaleX, self.scaleY)

    local bombSize = self.ballImage:getWidth() * self.scaleX
    local fontSize = 36
    love.graphics.setFont(love.graphics.newFont(fontSize))

    love.graphics.draw(self.ballImage, self.screenWidth / 2 - bombSize * 3, bombSize / 4, 0, self.scaleX/1.3, self.scaleY/1.3)
    love.graphics.printf(self.scorePlayer1, self.screenWidth / 2 - bombSize * 3 - fontSize/4.5, bombSize / 4 + self.ball.wickPx, bombSize, "center")

    love.graphics.draw(self.ballImage, self.screenWidth / 2 + bombSize * 2, bombSize / 4, 0, self.scaleX/1.3, self.scaleY/1.3)
    love.graphics.printf(self.scorePlayer2, self.screenWidth / 2 + bombSize * 2 - fontSize/4.5, bombSize / 4 + self.ball.wickPx, bombSize, "center")

    love.graphics.draw(self.ballImage, self.ball.x - bombSize / 2, self.ball.y - bombSize / 2, 0, self.scaleX, self.scaleY)
    love.graphics.draw(self.leftPaddle.image, self.leftPaddle.x, self.leftPaddle.y, 0, self.scaleX, self.scaleY)
    love.graphics.draw(self.rightPaddle.image, self.rightPaddle.x, self.rightPaddle.y, 0, self.scaleX, self.scaleY)
    

    if self.isGameOver or self.flagPause then
        love.graphics.draw(self.pauseOrLoseBg, 0, 0, 0, self.scaleX, self.scaleY)

        if self.isGameOver then
            local gameOverMessage = ""
            if self.scorePlayer1 > self.scorePlayer2 then
                gameOverMessage = "zehahaha, player 1 win!"
            else
                gameOverMessage = "zehahaha, player 2 win!"
            end
            local gameOverFontSize = fontSize * 3 * self.scaleX * self.scaleY
            love.graphics.setFont(love.graphics.newFont(gameOverFontSize))
            love.graphics.printf(gameOverMessage, 0, self.screenHeight / 4, self.screenWidth, "center")
            love.graphics.setFont(love.graphics.newFont(fontSize))
        end

        -- Отрисовка кнопок
        for _, button in pairs(self.visibleButtons) do
            if button.selected then
                love.graphics.setColor(1, 1, 1, 0.96)
            else
                love.graphics.setColor(0.5, 0.5, 0.5, 0.92)
            end
            love.graphics.draw(button.image, button.x, button.y, 0, self.scaleX, self.scaleY)
        end

        -- Восстановление цвета
        love.graphics.setColor(1, 1, 1)
    end
end

function Game:togglePause()
    self.flagPause = not self.flagPause
    if self.flagPause == true then
        self.ball.prevDx = self.ball.dx
        self.ball.prevDy = self.ball.dy
        self.ball.dx = 0
        self.ball.dy = 0
    end
    if self.flagPause == false then
        self.ball.dx = self.ball.prevDx
        self.ball.dy = self.ball.prevDy
    end
end

function Game:update(dt)
    -- Обновление положения мяча
    if self.isGameOver == false and self.flagPause == false then
        if love.keyboard.isDown("w") or love.keyboard.isDown("s") then
            self.leftFlagStart = true
        end
        if love.keyboard.isDown("up") or love.keyboard.isDown("down") then
            self.rightFlagStart = true
        end
    end

    if self.leftFlagStart and self.rightFlagStart then
        self.gameStart = true 
    end

    if self.gameStart then
        self.ball.x = self.ball.x + self.ball.dx
        self.ball.y = self.ball.y + self.ball.dy
    end

    -- Обработка столкновения мяча с верхней и нижней стенками
    if self.ball.y - self.ball.size * self.scaleY < 0 or self.ball.y + self.ball.size * self.scaleY  + self.ball.wickPx > self.screenHeight then
        self.ball.dy = -self.ball.dy
    end

    -- Обработка столкновения мяча с ракетками
    if self.ball.x - self.ball.size < self.leftPaddle.x + self.leftPaddle.width and self.ball.x + self.ball.size >
        self.leftPaddle.x and self.ball.y + self.ball.size > self.leftPaddle.y and self.ball.y - self.ball.size <
        self.leftPaddle.y + self.leftPaddle.height then
        self.ball.dx = -self.ball.dx
        if self.soundEnabled == true then self.paddleHitSound:play() end
        self.ballDeflectionByCenterPaddle = (self.leftPaddle.y + self.leftPaddle.height / 2 - self.ball.y - self.ball.size / 2) / (self.leftPaddle.height / 2) * self.gameSpeed / 2
        self.ball.dy = -self.ballDeflectionByCenterPaddle
        self.ball.dx = self.gameSpeed - math.abs(self.ballDeflectionByCenterPaddle)
    end

    if self.ball.x - self.ball.size < self.rightPaddle.x + self.rightPaddle.width and self.ball.x + self.ball.size >
        self.rightPaddle.x and self.ball.y + self.ball.size > self.rightPaddle.y and self.ball.y - self.ball.size <
        self.rightPaddle.y + self.rightPaddle.height then
        self.ball.dx = -self.ball.dx
        if self.soundEnabled == true then self.paddleHitSound:play() end
        self.ballDeflectionByCenterPaddle = (self.rightPaddle.y + self.rightPaddle.height / 2 - self.ball.y - self.ball.size / 2) / (self.rightPaddle.height / 2) * self.gameSpeed / 2
        self.ball.dy = -self.ballDeflectionByCenterPaddle
        self.ball.dx = -self.gameSpeed + math.abs(self.ballDeflectionByCenterPaddle)
    end

    -- Обработка движения ракеток

    if self.isGameOver == false and self.flagPause == false then
        -- Обработка правой ракетки
        if not self.autoflag then
            if love.keyboard.isDown("up") and self.rightPaddle.y > 0 then
                self.rightPaddle.y = self.rightPaddle.y - self.rightPaddle.dy
            end
            if love.keyboard.isDown("down") and self.rightPaddle.y +
                self.rightPaddle.height < love.graphics.getHeight() then
                self.rightPaddle.y = self.rightPaddle.y + self.rightPaddle.dy
            end
        else
            if self.ball.y > self.rightPaddle.y + self.rightPaddle.height then
                self.rightPaddle.y = self.rightPaddle.y + self.autoPaddleSpeed
            elseif self.ball.y < self.rightPaddle.y then
                self.rightPaddle.y = self.rightPaddle.y - self.autoPaddleSpeed
            end
        end

        -- Обработка левой ракетки
        if love.keyboard.isDown("w") and self.leftPaddle.y > 0 then
            self.leftPaddle.y = self.leftPaddle.y - self.leftPaddle.dy
        end
        if love.keyboard.isDown("s") and self.leftPaddle.y + self.leftPaddle.height < love.graphics.getHeight() then
            self.leftPaddle.y = self.leftPaddle.y + self.leftPaddle.dy
        end
    end

    -- Включение авторежима игрока справа (Симулирование игры против бота)
    if love.keyboard.isDown("k") then
        self.autoflag = not self.autoflag
    end

    -- Обновление положение мяча + увеличение счета
    if self.ball.x < 0 or self.ball.x > self.screenWidth then
        local scoreIncrement = 0
        if self.ball.x < 0 then
            scoreIncrement = 1
        else
            scoreIncrement = 2
        end
        self.scorePlayer1 = self.scorePlayer1 + math.floor(scoreIncrement / 2)
        self.scorePlayer2 = self.scorePlayer2 + math.floor(scoreIncrement % 2)
        if self.soundEnabled == true then self.scoreSound:play() end
        self.leftFlagStart = false
        self.rightFlagStart = false
        self.gameStart = false
        self.ball.x = self.screenWidth / 2
        self.ball.y = self.screenHeight / 2
        self.rand = math.random(self.gameSpeed / 2, self.gameSpeed)
        self.ball.dx = self.rand
        self.ball.dy = self.gameSpeed - self.ball.dx
    end

    if self.scorePlayer1 >= 3 or self.scorePlayer2 >= 3 then
        self.isGameOver = true
        self.visibleButtons = self:getVisibleButtons()
    end

    for i, button in pairs(self.buttons) do
        if button.callback == self.toggleSound then
            button.image = self.soundIcon
        end
    end
end

function Game:mousepressed(x, y, button, istouch, presses)
    for i, button in pairs(self.buttons) do
        if x >= button.x and x <= button.x + button.image:getWidth() and y >= button.y and y <= button.y + button.image:getHeight() then
            if button.callback then
                button.callback()
            end
        end
    end
end

function Game:keypressed(key)
    if self.isGameOver == true or self.flagPause == true then
        if key == "return" or key == "kpenter" then
            -- Выполнение обратного вызова активной кнопки
            local activeButton = self:getActiveButton()
            if activeButton and activeButton.callback then
                activeButton.callback()
            end
        elseif key == "up" then
            self:moveSelection(-1)
        elseif key == "down" then
            self:moveSelection(1)
        end
    end
    if self.isGameOver == false then
        if key == "escape" then
            self:togglePause()
            self.visibleButtons = self:getVisibleButtons()
        end
    end
end

function Game:moveSelection(direction)
    -- Найти текущую выбранную кнопку
    local currentButton = self:getActiveButton()
    -- Снять выделение с текущей кнопки
    if currentButton then
        currentButton.selected = false
    end
    
    -- Вычислить индекс следующей кнопки
    local currentIndex = 1
    if currentButton then
        for i, button in ipairs(self.visibleButtons) do
            if button == currentButton then
                currentIndex = i
                break
            end
        end
    
        local nextIndex = ((currentIndex - 1) + direction) % #self.visibleButtons + 1
    
        -- Выделить следующую кнопку
        local nextButton = self.visibleButtons[nextIndex]
        if nextButton then
            nextButton.selected = true
        end
    end
end

function Game:getVisibleButtons()
    -- Возвращает массив только отображаемых кнопок
    local newVisibleButtons = {}
    for i, button in ipairs(self.buttons) do
        if (button.name == "tryAgain" and not self.flagPause) or
           (button.name == "continue" and not self.isGameOver) or
           (button.name == "sound" and not self.isGameOver) then
            table.insert(newVisibleButtons, button)
        end
    end
    newVisibleButtons[1].selected = true
    return newVisibleButtons
end


function Game:getActiveButton()
    for _, button in ipairs(self.visibleButtons) do
        if button.selected then
            return button
        end
    end
    return nil
end

