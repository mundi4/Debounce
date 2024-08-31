# Debounce

This is an addon for key bindings in World of Warcraft. It allows you to assign keys for different spells, items, macros and more.

This addon is meant to work alongside WoW’s default key binding UI, not replace it. I use WoW's key binding UI for basic stuff like movement and opening bags, and this addon for class, specialization, or other conditional bindings.

#### Download Links
- [curseforge](https://www.curseforge.com/wow/addons/debounce)

**Note:** This addon won’t mess with your existing key bindings or settings. If you don’t like it, you can just turn it off or delete it.


## Features
- Role-based targets (`tank`, `healer`, `maintank`, and `mainassist`)
- Custom targets (`custom1` and `custom2`)
- Click casting (like Clique)
- Conditional bindings
- Custom states



## Usage
1. Run `/deb` or `/debounce` to open the UI.
2. Drag and drop a spell, item, or macro in the center of UI window. You can also add special actions by clicking the "Add" button.
3. Left-click the added action to assign a key. Right-click for more settings.
4. Use the tabs below to switch between shared and character-specific bindings. To switch between general, class, and specialization-specific bindings, use the tabs on the right. Key bindings that match your current class and specialization will be activated.



## Available Actions
1. **Spells**
2. **Items**
3. **Macros**
4. **Mounts**
5. **Macro Texts** - Macros that only work within this addon. You can use target conditions with special units such as `@healer` or `@custom1` (e.g., `/cast [@healer] Innervate`).
6. **Binding Commands** - Bindings from WoW's default key binding UI.
7. **Unused** - If the conditions for this action are met, the key binding assigned to this action in the addon is not used. This is useful if you want to intentionally ignore this addon’s binding for a specific key and use the binding set in WoW’s default key binding UI for certain situations.
8. **...**



## Special Conditions
Conditions that activate key bindings:

- **Hover**: Activates the key binding based on the unit frame your mouse is currently over.
- **Combat**: Activates the key binding depending on whether you are in combat.
- **Shapeshift**: Activates the key binding based on your current shapeshift form, if applicable.
- **Unit**: Activates the key binding based on specific units or unit roles, such as `@tank` or `@healer`.
- **Group**: Activates the key binding depending on whether you are in a group or raid.
- **Custom States**: Activates the key binding based on custom states you have set, which can be toggled on or off.
- **...**: Additional conditions can also be specified as needed.

**Note:** If none of the actions for the key match the special conditions, the key will default to the binding you set in WoW’s basic key binding UI.



## Targeting
In addition to the units supported by WoW, you can use special units such as `tank`, `healer`, `maintank`, `mainassist`, `custom1`, `custom2`, and `hover` (the unit frame currently moused over). You can refer to these units with `@tank`, `@healer`, `@maintank`, `@mainassist`, `@custom1`, `@custom2`, or `@hover` in **Macro Texts** (e.g., `/cast [@custom2,exists][@healer,exists][] Innervate`).

**Note:** It is not necessary to use **Macro Texts** to specify a special unit as the target for an action. You can also set this target using the right-click menu for spell or item actions.

### Role-based Targets
- Tank (@tank)
- Healer (@healer)
- Main Tank (@maintank)
- Main Assist (@mainassist)

**Note:** This will only work if there is exactly one unit assigned to that role in the party/raid.


#### Custom Targets
You can set up to two custom targets, which function similarly to the focus target. You can use these custom targets as the targets of your actions or in the **Macro Texts** with `@custom1` and `@custom2`. (e.g., `/cast [@custom1,exists][] Rejuvenation`)

**You can assign a custom target from the following units:** `player`, `pet`, `party1` to `party4`, `raid1` to `raid40`, `boss1` to `boss8`, `arena1` to `arena5`.

To assign a custom target, first add the **Set Custom Target** action and assign a key to it. Then, you can use that key to set the unit of the unit frame you are mousing over as a custom target.



## Custom States
Custom States function similarly to Logitech’s G Shift or Razer’s Hypershift. These states can be used as special conditions or macro conditional expressions. You can turn these states on or off at any time (even in combat), or set them as macro conditionals. For example, using a macro conditional like [@tank,exists] will automatically turn on the state when `@tank` exists.

You can assign these states as special conditions in the right-click menu, just like other special conditions.

In Macro Text actions, you can use these states as follows:

- `/cast [$state1] SomeSpell`
- `/cast [no$state1] SomeSpell`



## Priorities
You can assign the same key to multiple actions that you add. When the key is pressed, the action that matches the current conditions and has the highest priority will be selected. The priority is determined by the following rules:

1. **User-defined Priority Values**: Very High, High, Normal (default), Low, Very Low
2. **Special Conditions**:
    1. If the hover condition is specified, it has a higher priority than other conditions.
    2. Any other special conditions specified have a higher priority than those that are not.
3. **Priority of Tabs**:
    1. Character-specific/Specialization-specific (Highest)
    2. Character-specific
    3. Shared/Specialization-specific
    4. Shared/Class-specific
    5. Shared/General (Lowest)
4. **Action Position**: The action higher in the list has a higher priority than those below it. You can adjust this by dragging the actions.



## Using Clique?
If you use Clique alongside this addon, some features related to unit frames may not be available. While this addon includes some of Clique's features, it may not fully replace Clique, a reliable addon that has been working well for a long time. You'll need to test it yourself to see if it fits your needs.



## Questions or Want to Help?
- Oreo-Durotan(kr) (Alliance)
- mundi4@gmail.com
- [GitHub](https://github.com/mundi4/Debounce)

