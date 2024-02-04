# Debounce

This is an addon for key bindings in World of Warcraft. It allows you to assign keys for different spells, items, macros and more.

### **This addon does not change any of the WoW's key bindings or settings. If you don't like the addon, you can just turn it off or delete it.**

This addon is not meant to replace the default key bindings of WoW. Rather, it is designed to be used on top of the default key bindings. I personally use the default key bindings for simple keys that are common to all characters (such as movement keys, opening bags, etc.) with the character-specific key bindings turned off. For the rest of the keys that depend on the class, specialization, character, or situation, I use this addon to set them up.


## Small Features
- Targets special units such as tanks, healer or custom targets.
- Click Casting (like Clique)
- Conditional bindings.


## Usage
1. Run `/deb` or `/debounce` to open the UI.
2. Drag and drop a spell, item or macro in the middle of UI window. You can also add some special actions by clicking the Add button.
3. Left click the added action to assign a key. Right click for more settings.
4. Use the tabs below to switch between shared and character-specific bindings. To switch between general, class, and specialization specific bindings, use the tabs on the right. All the key bindings for the tabs that match your current class/specialization will be activated.


## Available Actions
1. Spells
2. Items
3. Macros
4. Mounts
5. Macro Texts - **Macros that only work within this addon**. You can use target conditions with special units such as `@healer` or `@custom1` (Example: `/cast [@healer] Innervate`).
6. Binding Commands - the Bindings in WoW's default key bindings UI.
7. and More


## Targeting
In addition to the ones that are supported by WoW, you can use special units, such as tank, healer, maintank, mainassist, custom1, custom2, and hover (the unit of the unit frame that is moused over). You can refer to these units with `@tank`, `@healer`, `@maintank`, `@mainassist`, `@custom1`, `@custom2`, or `@hover` in **Macro Texts**. (Example: `/cast [@custom2,exists][@healer,exists][] Innervate`)


#### Custom Targets
You can set up to two custom targets that work similarly to the focus target. You can use the custom targets as the targets of your actions or in the **Macro Texts** with `@custom1` and `@custom2`. (Example: `/cast [@custom1,exists][] Rejuvenation`)

**You can assign a custom target from these units: `player`, `pet`, `party1~4`, `raid1~40`, `boss1~8`, `arena1~5`**

To assign a custom target, you should first add the *Set Custom Target* action and assign a key to it. Then, you can use that key to set the unit of the unit frame that you mouse over as a custom target. Alternatively, you can use this command: `/click DebounceCustom1 hover`.



## Priorities
You can assign the same key to multiple actions that you added. In this case, the action that has the highest priority for the current situation will be selected. The priority is determined by the following rules.

1. Priority value that set by the user: Very High, High, Normal, Low, Very Low
2. If there are special conditions set by the user
    1. If the hover condition is specified, it has a higher priority than otherwise.
    2. If any other special conditions are specified, they have a higher priority than those that are not.
3. Priority of tabs that contain actions.
    1. Character-specific/Specialization-specific (Highest)
    2. Character-specific
    3. Shared/Specialization-specific
    4. Shared/Class-specific
    5. Shared General(Lowest)
4. The position of the action in the tab. The action above has a higher priority than the action below. You can change this by dragging.


## Special Conditions
Special conditions are dynamically applied during combat.


### Hovering over a Unit Frame
Whether hovering over a unit frame or not. This condition also assigns the unit of the unit frame that is being hovered over as a target of the action by default.


## Using Clique?
If you use Clique and this addon at the same time, you will not be able to use some of the features of this addon (such as those related to unit frames). This addon includes some of Clique's features, but I don't know if it's good enough to replace Clique, a reliable addon that has been working well for a long time... You'll have to test it yourself.


## I appreciate any help!
- Oreo-Durotan(kr) (Alliance)
- mundi4@gmail.com

