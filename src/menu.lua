-- menu.lua

Menu = {}

function Menu:new()
    -- Загрузка изображения фона, изображения корабля и музыки меню
    local background = love.graphics.newImage("assets/img/bg_menu.png")
    local spaceshipImage = love.graphics.newImage("assets/img/ship.png")
    local menuMusic = love.audio.newSource("assets/sounds/s_menu.mp3", "stream")
    local soundOnImage = love.graphics.newImage("assets/img/s_on.png")
    local soundOffImage = love.graphics.newImage("assets/img/s_off.png")

    -- Инициализация корабля
    local spaceship = {
        image = spaceshipImage,
        x = screenWidth / 2 - spaceshipImage:getWidth() / 2,
        y = screenHeight / 2 - spaceshipImage:getHeight() / 2
    }

    -- Инициализация меню
    local menu = {
        buttons = {},
        background = background,
        menuMusic = menuMusic,
        soundOnImage = soundOnImage,
        soundOffImage = soundOffImage,
        soundIcon = soundOnImage,
        soundEnabled = true,
        spaceship = spaceship,
        screenWidth = screenWidth,
        screenHeight = screenHeight,
        scaleX = screenWidth / background:getWidth(),
        scaleY = screenHeight / background:getHeight()
    }

    setmetatable(menu, { __index = self })

    -- Добавление кнопок
    menu:addButton("play", "button_play.png", menu.screenWidth/2, menu.screenHeight/2, function() currentGameState=gameState.GAME end)
    menu:addButton("exit", "button_exit.png", menu.screenWidth/2 , menu.screenHeight/2, function() love.event.quit() end)

    local soundButton = {
        name = "sound",
        image = soundOnImage,
        x = 10,
        y = 10,
        width = soundOnImage:getWidth(),
        height = soundOnImage:getHeight(),
        callback = function() menu:toggleSound() end
    }

    table.insert(menu.buttons, soundButton)

    return menu
end

function Menu:startMusic()
    -- Установка музыки на повторение и воспроизведение
    self.menuMusic:setLooping(true)
    love.audio.play(self.menuMusic)
end

function Menu:stopMusic()
    self.menuMusic:setLooping(false)
    love.audio.stop(self.menuMusic)
end

function Menu:toggleSound()
    self.soundEnabled = not self.soundEnabled

    if self.soundEnabled then
        self.soundIcon = self.soundOnImage
    else
        self.soundIcon = self.soundOffImage
    end
    for i, button in ipairs(self.buttons) do
        -- ToDo, сейчас проверка по костылю, поменять бы (сомнительно, но оукей)
        if button.name == "sound" then
            button.image = self.soundIcon
        end
    end
end

function Menu:addButton(name, imageFile, x, y, callback)
    -- Создание изображения кнопки и добавление кнопки в массив
    local buttonImage = love.graphics.newImage("assets/img/" .. imageFile)
    local button = {
        name = name,
        image = buttonImage,
        x = x - buttonImage:getWidth()/2 * self.scaleX,
        y = y - buttonImage:getHeight() / 2 * self.scaleY + (#self.buttons * buttonImage:getHeight() * self.scaleY),
        selected = false,
        callback = callback,
        buttonMargin = buttonImage:getHeight() * self.scaleY * 1.5
    }

    table.insert(self.buttons, button)

    -- Пересчет координат всех кнопок после добавления новой
    local totalButtonHeight = #self.buttons * buttonImage:getHeight() * self.scaleY
    local centerY = self.screenHeight / 2

    for i, button in ipairs(self.buttons) do
        if i == 1 then button.selected = true end
        button.y = centerY - totalButtonHeight / 2 + (i - 1) * button.buttonMargin
    end
end

function Menu:draw()
    -- Установка цвета фона
    love.graphics.setBackgroundColor(255, 255, 255)

    -- Отрисовка фона
    love.graphics.draw(self.background, 0, 0, 0, self.scaleX, self.scaleY)
    
    -- Затемнение фона полупрозрачным прямоугольником
    love.graphics.setColor(0, 0, 0, 0.2)  -- Настройка значения альфа для желаемой темноты
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)
    love.graphics.setColor(1, 1, 1, 1)  -- Сброс цвета для предотвращения влияния на другие рисунки

    -- Отрисовка корабля
    love.graphics.draw(self.spaceship.image, self.spaceship.x, self.spaceship.y, 0)
    
    -- Отрисовка кнопок
    for i, button in pairs(self.buttons) do
        if button.selected then
            love.graphics.setColor(1, 1, 1, 0.96)
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 0.92)
        end
        love.graphics.draw(button.image, button.x, button.y, 0, self.scaleX, self.scaleY)
    end

    -- Восстановление цвета
    love.graphics.setColor(1,1,1)
end

function Menu:update(dt)
    -- Движение корабля по горизонтали
    local speed = 75 -- Контроль скорости
    self.spaceship.x = self.spaceship.x + speed * dt

    -- Перемещение корабля обратно на экране после выхода за пределы
    if self.spaceship.x > self.screenWidth then
        self.spaceship.x = -self.spaceship.image:getWidth()
    end

    for i, button in pairs(self.buttons) do
        if button.callback == self.toggleSound then
            button.image = self.soundIcon
        end
    end

    -- выделение selected с помощью мыши
    -- local mx, my = love.mouse.getPosition()

    -- for i, button in ipairs(self.buttons) do
    --     if mx >= button.x and mx <= button.x + button.image:getWidth() and
    --        my >= button.y and my <= button.y + button.image:getHeight() then
    --         button.selected = true
    --     else
    --         button.selected = false
    --     end
    -- end
end

function Menu:mousepressed(x, y, button, istouch, presses)
    for i, button in pairs(self.buttons) do
        if x >= button.x and x <= button.x + button.image:getWidth() and y >= button.y and y <= button.y + button.image:getHeight() then
            if button.callback then
                button.callback()
            end
        end
    end
end

function Menu:keypressed(key)
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

function Menu:moveSelection(direction)
    -- Найти текущую выбранную кнопку
    local currentButton = self:getActiveButton()
    
    -- Снять выделение с текущей кнопки
    if currentButton then
        currentButton.selected = false
    end
    
    -- Вычислить индекс следующей кнопки
    local currentIndex = 1
    if currentButton then
        for i, button in ipairs(self.buttons) do
            if button == currentButton then
                currentIndex = i
                break
            end
        end
    
        local nextIndex = ((currentIndex - 1) + direction) % #self.buttons + 1
    
        -- Выделить следующую кнопку
        local nextButton = self.buttons[nextIndex]
        if nextButton then
            nextButton.selected = true
        end
    end
end



function Menu:getActiveButton()
    for _, button in ipairs(self.buttons) do
        if button.selected then
            return button
        end
    end
    return nil
end