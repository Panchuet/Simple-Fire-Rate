behaviour("SimpleFireRate")

-- Keys:
--   startSlow             (bool)   : If true, the weapon starts with the slow fire rate instead of fast
--   fastCooldown          (float)  : Time between shots in seconds for the fast fire rate mode
--   slowCooldown          (float)  : Time between shots in seconds for the slow fire rate mode
--   switchCooldown        (float)  : Lockout time in seconds before you can switch modes again, best if you match the switch animation length
--   switchKeybind         (string) : Lowercase keybind of the key you want to use to switch modes
--   switchParameterName   (string) : Name of the animator trigger parameter to play on switch
--   selectorValues        (string) : Two space-separated integers for the selector lever position per mode e.g. "0 1" (mode 0 = fast, mode 1 = slow)
--   selectorParameterName (string) : Name of the animator integer parameter that holds the selector lever position

function SimpleFireRate:Start()
    self.weapon = self.gameObject.GetComponent(Weapon)
    self.animator = self.gameObject.GetComponent(Animator)
    self.dataContainer = self.gameObject.GetComponent(DataContainer)

    self.modeIndex = self.dataContainer.GetBool("startSlow") and 1 or 0
    self.fastCooldown = self.dataContainer.GetFloat("fastCooldown")
    self.slowCooldown = self.dataContainer.GetFloat("slowCooldown")
    self.switchCooldown = self.dataContainer.GetFloat("switchCooldown")
    self.switchKeybind = self.dataContainer.GetString("switchKeybind")

    self.selectorValues = {}
    for match in (self.dataContainer.GetString("selectorValues") .. " "):gmatch("(.-) ") do
        table.insert(self.selectorValues, tonumber(match))
    end
    
    if self.animator ~= nil then
        self.switchParameter = self.animator.StringToHash(self.dataContainer.GetString("switchParameterName"))
        self.selectorParameter = self.animator.StringToHash(self.dataContainer.GetString("selectorParameterName"))
    end

    self.switchTimer = 0
    self:ApplyMode()
end

function SimpleFireRate:ApplyMode()
    self.weapon.cooldown = self.modeIndex == 0 and self.fastCooldown or self.slowCooldown
    
    if self.animator ~= nil then
        self.animator.SetInteger(self.selectorParameter, self.selectorValues[self.modeIndex + 1])
    end
end

function SimpleFireRate:SwitchMode()
    self.modeIndex = 1 - self.modeIndex
    self.switchTimer = self.switchCooldown
    self.weapon.LockWeapon()
    
    if self.animator ~= nil then
        self.animator.SetTrigger(self.switchParameter)
    end
    
    self:ApplyMode()
end

function SimpleFireRate:OnEnable()
    if self.animator == nil then return end
    self.animator.SetInteger(self.selectorParameter, self.selectorValues[self.modeIndex + 1])
end

function SimpleFireRate:Update()
    if self.weapon == nil then return end

    if self.switchTimer > 0 then
        self.switchTimer = self.switchTimer - Time.deltaTime

        if self.switchTimer <= 0 then
            self.weapon.UnlockWeapon()
        end
    end

    if self.switchTimer <= 0
        and not self.weapon.isReloading
        and self.weapon.user ~= nil
        and self.weapon.user.isPlayer
        and Input.GetKeyDown(self.switchKeybind)
    then
        self:SwitchMode()
    end
end