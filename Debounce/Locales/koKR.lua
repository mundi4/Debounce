local _, addon = ...;
local L = addon.L;
if GetLocale() ~= "koKR" then return end

L["_HAS_TOOLTIP_SUFFIX"] = " |cffffff00(*)|r"
L["_MESSAGE_PREFIX"] = "|cff3b9de3[Debounce]|r "
L["ACTIONBARS"] = "행동 단축바"
L["ADD"] = "추가..."
L["ALL"] = "모두"
L["BINDING_COMMAND_PAGE_FORMAT"] = "%d / %d"
L["BINDING_ERROR_BONUSBARS_NONE_SELECTED"] = "아무 태세 행동 단축바 조건도 선택되지 않았습니다."
L["BINDING_ERROR_CANNOT_USE_HOVER_WITH_CLIQUE"] = "Clique와 함께 사용할 수 없습니다!"
L["BINDING_ERROR_CONDITIONS_NEVER"] = "동시에 충족될 수 없는 조건들을 포함합니다."
L["BINDING_ERROR_FORMS_NONE_SELECTED"] = "아무 변신 조건도 선택되지 않았습니다."
L["BINDING_ERROR_GROUPS_NONE_SELECTED"] = "아무 파티/공격대 조건도 선택되지 않았습니다."
L["BINDING_ERROR_HOVER_NONE_SELECTED"] = "개체창과의 관계 또는 개체창 종류가 선택되지 않았습니다."
L["BINDING_ERROR_NOT_SUPPORTED_GAMEMENU_KEY"] = "|cFFFFFF00게임 메뉴 열기/닫기|r로 지정된 단축키는 사용할 수 없습니다."
L["BINDING_ERROR_NOT_SUPPORTED_HOVER_CLICK_COMMAND"] = "단축키 명령은 개체창 위에서 마우스 버튼으로 실행할 수 없습니다"
L["BINDING_ERROR_NOT_SUPPORTED_MOUSE_BUTTON"] = "마우스 왼쪽/오른쪽 버튼은 개체창 위에서만 사용할 수 있습니다."
L["BINDING_ERROR_UNREACHABLE"] = "다른 행동이 우선적으로 실행되기 때문에 이 행동은 실행되지 않습니다."
L["BINDING_TITLE"] = "%2$s (%1$s)"
L["BLIZZARD_UNIT_FRAMES_ARENA"] = "투기장 개체창"
L["BLIZZARD_UNIT_FRAMES_BOSS"] = "우두머리 개체창"
L["BLIZZARD_UNIT_FRAMES_PARTY"] = "파티 개체창"
L["BLIZZARD_UNIT_FRAMES_PET"] = "소환수창"
L["BLIZZARD_UNIT_FRAMES_PLAYER"] = "플레이어 개체창"
L["BLIZZARD_UNIT_FRAMES_RAID"] = "공격대창"
L["BLIZZARD_UNIT_FRAMES_TARGET"] = "대상 및 주시 대상"
L["BLIZZARD_UNIT_FRAMES"] = "기본 블리자드 개체창"
L["CANNOT_OPEN_IN_COMBAT"] = "전투 중에는 열 수 없습니다."
L["CHARACTER_SPECIFIC_BINDINGS"] = "%s 전용 단축키"
L["CONDITION_BONUSBAR"] = "변신/태세에 따른 행동 단축바"
L["CONDITION_COMBAT_NO"] = "전투 중이 아닐 때"
L["CONDITION_COMBAT_YES"] = "전투 중일 때"
L["CONDITION_COMBAT"] = "전투"
L["CONDITION_CUSTOMSTATE_NO"] = "꺼짐 상태일 때"
L["CONDITION_CUSTOMSTATE_YES"] = "켜짐 상태일 때"
L["CONDITION_EXTRABAR_NO"] = "기타 행동 버튼이 표시 중이 아닐 때"
L["CONDITION_EXTRABAR_YES"] = "기타 행동 버튼이 표시 중일 때"
L["CONDITION_EXTRABAR"] = "기타 행동 버튼"
L["CONDITION_FRAMETYPES"] = "개체창 종류"
L["CONDITION_GROUP"] = "파티/공격대";
L["CONDITION_HOVER_NO"] = "마우스를 올리지 않았을 때"
L["CONDITION_HOVER_YES"] = "마우스를 올렸을 때"
L["CONDITION_HOVER"] = "개체창 위 마우스"
L["CONDITION_PET_NO"] = "소환수가 없을 때"
L["CONDITION_PET_YES"] = "소환수가 있을 때"
L["CONDITION_PET"] = "소환수"
L["CONDITION_PETBATTLE_NO"] = "애완동물 대전 중이 아닐 때"
L["CONDITION_PETBATTLE_YES"] = "애완동물 대전 중일 때"
L["CONDITION_PETBATTLE"] = "애완동물 대전"
L["CONDITION_REACTIONS"] = "개체창과의 관계"
L["CONDITION_SHAPESHIFT"] = "변신"
L["CONDITION_SPECIALBAR_DESC"] = "탈것, 지배 등 기본 행동 단축바가 대체된 상태에 의한 조건입니다."
L["CONDITION_SPECIALBAR_NO"] = "특수 행동 단축바 상태가 아닐 때"
L["CONDITION_SPECIALBAR_YES"] = "특수 행동 단축바 상태일 때"
L["CONDITION_SPECIALBAR"] = "특수 행동 단축바"
L["CONDITION_STEALTH_NO"] = "은신 중이 아닐 때"
L["CONDITION_STEALTH_YES"] = "은신 중일 때"
L["CONDITION_STEALTH"] = "은신"
L["CONDITION_UNIT_DOES_NOT_EXIST"] = "개체가 존재하지 않을 때"
L["CONDITION_UNIT_EXISTS"] = "개체가 존재할 때"
L["CONDITION_UNIT_HARM"] = "개체가 적대적일 때"
L["CONDITION_UNIT_HELP"] = "개체가 우호적일 때"
L["CONDITION_UNIT"] = "개체"
L["CONFIRM_CURRENT_CHANGE_FIRST"] = "현재 변경을 먼저 마무리하세요."
L["CONVERT_TO_MACRO_TEXT"] = "|cnLIGHTBLUE_FONT_COLOR:매크로 문자열|r로 변환"
L["COPY_TO"] = "복사"
L["CURRENT_TAB"] = "현재 위치"
L["CUSTOM_STATE_CURRENT_VALUE"] = "현재 값"
L["CUSTOM_STATE_DISPLAY_MESSAGE"] = "변경 시에 메시지 표시하기"
L["CUSTOM_STATE_EDIT_VALUE_DESC"] = "매크로 조건문을 입력하세요.\n(예: |cffffff00[@tank,exists,combat]|r)"
L["CUSTOM_STATE_EDIT_VALUE"] = "매크로 조건문 입력."
L["CUSTOM_STATE_INITIAL_VALUE"] = "초기값"
L["CUSTOM_STATE_LOGIN_OFF"] = "접속 시에 꺼짐"
L["CUSTOM_STATE_LOGIN_ON"] = "접속 시에 켜짐"
L["CUSTOM_STATE_MODE_MACRO_CONDITIONAL_DESC"] = "사용자가 입력한 매크로 조건문에 의해 상태를 자동으로 켜고 끕니다 (예: |cnHIGHLIGHT_FONT_COLOR:[@healer,exists]|r)."
L["CUSTOM_STATE_MODE_MACRO_CONDITIONAL"] = "자동으로 켜고 끄기"
L["CUSTOM_STATE_MODE_MANUAL_DESC"] = "상태를 사용자가 직접 켜거나 끕니다."
L["CUSTOM_STATE_MODE_MANUAL_INSTRUCTION"] = "이 메뉴에서 상태를 켜고 끄거나 |cnBLUE_FONT_COLOR:사용자 상태 지정|r 행동을 사용해서 전투 중을 포함해 언제든지 켜고 끌 수 있습니다."
L["CUSTOM_STATE_MODE_MANUAL"] = "수동으로 켜고 끄기"
L["CUSTOM_STATE_NUM"] = "사용자 상태 %d"
L["CUSTOM_STATE_OFF"] = "꺼짐"
L["CUSTOM_STATE_ON"] = "켜짐"
L["CUSTOM_STATE_REMEMBER"] = "접속 시에 마지막 상태 값 불러오기"
L["CUSTOM_STATE_TOGGLE"] = "켜짐/꺼짐 전환"
L["CUSTOM_STATE_TURN_OFF"] = "끄기"
L["CUSTOM_STATE_TURN_ON"] = "켜기"
L["CUSTOM_STATES_DESC"] = "특수 조건이나 매크로 문자열에서 조건문(예: |cnHIGHLIGHT_FONT_COLOR:[$state1]|r)으로 사용할 수 있는 켜짐/꺼짐 상태입니다. 단축키 설정을 통해 상태를 켜고 끄거나 매크로 조건문으로 설정하여 자동으로 켜거나 끌 수 있습니다."
L["CUSTOM_STATES"] = "사용자 상태"
L["CUSTOM_TARGET_FAILED"] = "|cnHIGHLIGHT_FONT_COLOR:%s|r: |cffff0000지정 실패: %s|r"
L["CUSTOM_TARGET_HELP_MESSAGE_ARENA"] = "투기장 개체창 위에서 사용하세요."
L["CUSTOM_TARGET_HELP_MESSAGE_BOSS"] = "우두머리 개체창 위에서 사용하세요."
L["CUSTOM_TARGET_HELP_MESSAGE_GROUP"] = "파티/공격대창 위에서 사용하세요."
L["CUSTOM_TARGET_HELP_MESSAGE_PET"] = "소환수창 위에서 사용하세요."
L["CUSTOM_TARGET_HELP_MESSAGE_PLAYER"] = "플레이어 개체창 또는 파티/공격대창 위에서 사용하세요."
L["CUSTOM_TARGET_INVALIDATED"] = "|cnHIGHLIGHT_FONT_COLOR:%s|r - |cffff0000파티/공격대 구성 변경으로 인해 해제되었습니다.|r"
L["CUSTOM_TARGET_SET_VOLATILE"] = "|cnHIGHLIGHT_FONT_COLOR:%s|r - %s (전투가 종료되기 전에 파티/공격대 구성이 변경될 경우 해제될 수 있습니다.)"
L["CUSTOM_TARGET_UNSUPPORTED_UNIT_IN_COMBAT"] = "|cnHIGHLIGHT_FONT_COLOR:%s|r - |cffff0000전투 중에는 '%s' 개체로부터 지정할 수 없습니다. %s|r"
L["CUSTOM_TARGET_UNSUPPORTED_UNIT"] = "|cnHIGHLIGHT_FONT_COLOR:%s|r - |cffff0000지원되지 않는 개체: %s|r"
L["DEBOUNCE_OVERVIEW_TITLE"] = "Debounce 단축키 살펴보기"
L["DEBOUNCE_TITLE_FORMAT"] = "Debounce [%s - %s]"
L["DEFAULT"] = "기본"
L["DELETE_CONFIRM_MESSAGE"] = "삭제하시겠습니까?: %s"
L["DELETE"] = "삭제"
L["DISABLE"] = "이 조건 사용 안 함"
L["DISCARD"] = "변경 내용 버리기"
L["EDIT_MACRO"] = "매크로 편집"
L["ERROR_MESSAGE_CANNOT_SET_CUSTOM_TARGET_IN_COMBAT"] = "전투 중에는 명령어를 통해 사용자 대상을 지정할 수 없습니다."
L["EXCLUDE_PLAYER_DESC"] = "역할별 개체를 지정할 때 플레이어 본인은 제외합니다."
L["EXCLUDE_PLAYER"] = "본인 제외"
L["FRAMETYPE_ARENA"] = "투기장 개체창"
L["FRAMETYPE_BOSS"] = "우두머리 개체창"
L["FRAMETYPE_GROUP"] = "파티/공격대 개체창"
L["FRAMETYPE_PET"] = "소환수창"
L["FRAMETYPE_PLAYER"] = "플레이어 개체창"
L["FRAMETYPE_TARGET"] = "대상 및 주시 대상"
L["FRAMETYPE_UNKNOWN"] = "그 외 개체창"
L["GENERAL"] = "일반"
L["GROUP_NONE"] = "파티/공격대에 속해 있지 않을 때";
L["GROUP_PARTY"] = "파티에 속해 있을 때";
L["GROUP_RAID"] = "공격대에 속해 있을 때";
L["IGNORE_HOVER_UNIT_DESC"] = "선택할 경우 개체창의 개체를 대상으로 삼지 않습니다."
L["IGNORE_HOVER_UNIT"] = "개체창의 개체 무시"
L["INACTIVE_SPEC_LABEL"] = "%s (비활성화)"
L["KEY"] = "단축키"
L["KEYBIND_INSTRUCTION_TEXT"] = "마우스를 |cFF00FFFF이 창|r 위에 둔 채 원하는 키를 눌러서 선택된 행동에 대한 단축키를 지정합니다."
L["LINE_TOOLTIP_CONDITION_LABEL"] = "%s:"
L["LINE_TOOLTIP_INSTRUCTION_MESSAGE1"] = "왼쪽 클릭으로 단축키 지정"
L["LINE_TOOLTIP_INSTRUCTION_MESSAGE2"] = "오른쪽 클릭으로 더 많은 설정 보기"
L["LINE_TOOLTIP_INSTRUCTION_MESSAGE3"] = "끌어서 순서 변경 또는 다른 탭으로 이동"
L["LOGIN_MESSAGE"] = "설정창을 열려면 /deb 명령어를 사용하세요."
L["MACRO_POPUP_TEXT"] = "매크로 이름 (최대 32)"
L["MACROFRAME_CHAR_LIMIT"] = "현재 %d/1000 사용"
L["MISC"] = "기타"
L["MOVE_TO"] = "이동"
L["NEW_KEY_TEXT"] = "새 단축키: %s"
L["NO_ACTIONS_IN_THIS_TAB"] = "이 탭은 비어 있습니다. 주문, 매크로, 아이템 또는 탈것을 여기로 끌어다 놓으세요."
L["NO_SHAPESHIFT"] = "변신 중이 아닐 때"
L["NOT_BOUND"] = "지정 안 됨"
L["NOT_SELECTED"] = "선택되지 않음"
L["OPTIONS"] = "설정"
L["OTHER_OPTIONS"] = "추가 설정"
L["PET"] = "소환수"
L["PREVIOUS_KEY_TEXT"] = "이전 단축키: %s"
L["PRIORITY_DESC"] = "동일한 단축키를 여러개의 행동에 지정하는 경우, 지정된 특수 조건에 부합하는 행동들 중 우선 순위가 가장 높은 행동이 선택되어 실행됩니다. 우선 순위는 다음의 규칙에 의해 정해집니다.|n|n1. 이 메뉴에서 선택하는 우선 순위 값: 매우 높음 > 매우 낮음|n|n2. 특수 조건이 지정된 경우|n  2.1 개체창 위에 마우스를 올린 상태 조건을 사용하는 경우 그렇지 않은 경우보다 우선 순위가 높습니다.|n  2.2 그 외의 특수 조건을 사용하는 경우 그렇지 않은 경우보다 우선 순위가 높습니다.|n|n3. 행동이 위치한 창: 가장 세부적인 창(캐릭터 전용/전문화) > 가장 덜 세부적인 창 (일반)|n|n4. 같은 창에서 위쪽 위치한 행동이 아래쪽에 위치한 행동보다 우선 순위가 높습니다. 끌어서 위치를 변경하세요."
L["PRIORITY"] = "우선 순위"
L["PRIORITY1"] = "매우 높음"
L["PRIORITY2"] = "높음"
L["PRIORITY3"] = "보통 (기본값)"
L["PRIORITY4"] = "낮음"
L["PRIORITY5"] = "매우 낮음"
L["REACTION_ALL"] = "모두"
L["REACTION_HARM"] = "적대적"
L["REACTION_HELP"] = "우호적"
L["REACTION_OTHER"] = "그 외"
L["SAVE_OR_DISCARD_MESSAGE"] = "이 매크로에 저장되지 않는 변경 내용이 있습니다."
L["SAVE"] = "변경 내용 저장"
L["SELECTED_TARGET_UNIT_EMPTY"] = "대상으로 지정된 개체 |cnDISABLED_FONT_COLOR:(없음)|r"
L["SELECTED_TARGET_UNIT"] = "대상으로 지정된 개체 |cnBLUE_FONT_COLOR:(%s)|r"
L["SHARED_BINDINGS"] = "공용 단축키"
L["SPECIAL_CONDITIONS"] = "특수 조건"
L["SPECIAL_UNIT_SET_MESSAGE"] = "|cnHIGHLIGHT_FONT_COLOR:%s|r - %s"
L["SPECIAL_UNIT_UNSET_MESSAGE_TOO_MANY"] = "|cnHIGHLIGHT_FONT_COLOR:%s|r - |cff888888해제됨 (한 명을 초과함)|r"
L["SPECIAL_UNIT_UNSET_MESSAGE"] = "|cnHIGHLIGHT_FONT_COLOR:%s|r - |cff888888해제됨|r"
L["SPECIAL_UNITS"] = "특수 개체"
L["STATE_CHANGED_MESSAGE_OFF"] = "|cnRED_FONT_COLOR:꺼짐|r"
L["STATE_CHANGED_MESSAGE_ON"] = "|cnGREEN_FONT_COLOR:켜짐|r"
L["STATE_CHANGED_MESSAGE"] = "|cff82c5ff%s|r 변경: %s."
L["TARGET_UNIT_DESC"] = "선택된 개체를 대상으로 삼습니다. 개체창 조건을 사용하는 경우에도 개체창의 개체가 아닌 선택된 개체가 대상이 됩니다."
L["TARGET_UNIT"] = "대상 지정"
L["TYPE_COMMAND"] = "단축키 명령"
L["TYPE_FOCUS"] = "주시 대상으로 지정"
L["TYPE_ITEM"] = "아이템"
L["TYPE_MACRO"] = "매크로"
L["TYPE_MACROTEXT"] = "매크로 문자열"
L["TYPE_MACROTEXT_DESC"] = "이 애드온을 통해서만 사용할 수 있는 매크로입니다. 특수 개체나 사용자 상태 조건을 매크로에서 사용할 수 있습니다. (예: |cnHIGHLIGHT_FONT_COLOR:/cast [@tank,exists] 회복|r)"
L["TYPE_MOUNT"] = "탈것"
L["TYPE_SETCUSTOM_DESC"] = "개체창 위에서 키를 눌러 사용자 대상으로 지정합니다.\n(플레이어, 소환수, 파티/공격대, 우두머리, 투기장 개체창)"
L["TYPE_SETCUSTOM"] = "사용자 대상으로 지정"
L["TYPE_SETCUSTOM1"] = "1번 사용자 대상으로 지정"
L["TYPE_SETCUSTOM2"] = "2번 사용자 대상으로 지정"
L["TYPE_SETSTATE_DESC"] = "이 행동을 사용해 사용자 상태를 켜거나 끌 수 있습니다."
L["TYPE_SETSTATE_OFF_NUM"] = "사용자 상태 %d 끄기"
L["TYPE_SETSTATE_ON_NUM"] = "사용자 상태 %d 켜기"
L["TYPE_SETSTATE_TOGGLE_NUM"] = "사용자 상태 %d 켜기/끄기"
L["TYPE_SETSTATE"] = "사용자 상태 지정"
L["TYPE_SPELL"] = "주문"
L["TYPE_TARGET"] = "대상으로 지정"
L["TYPE_TOGGLEMENU"] = "메뉴 열기"
L["TYPE_UNUSED_DESC"] = "특정 상황에서 해당 단축키의 설정을 해제하고 싶은 경우 사용하세요."
L["TYPE_UNUSED"] = "단축키 사용 안 함"
L["TYPE_WORLDMARKER"] = "위치 표시기"
L["UNABLE_TO_REGISTER_UNIT_FRAME_IN_COMBAT"] = "전투 상태로 인해 몇몇 개체창에 설정을 마칠 수 없습니다. 전투가 끝난 후에 적용됩니다."
L["UNBIND"] = "키 설정 해제"
L["UNIT_CUSTOM1"] = "1번 사용자 대상"
L["UNIT_CUSTOM2"] = "2번 사용자 대상"
L["UNIT_DISABLE"] = "대상 지정 안 함"
L["UNIT_FOCUS"] = "주시 대상"
L["UNIT_HEALER"] = "치유 전담"
L["UNIT_HOVER_DESC"] = "마우스를 올린 개체창의 개체"
L["UNIT_HOVER"] = "개체창"
L["UNIT_MAINASSIST"] = "공격대 지원공격 전담"
L["UNIT_MAINTANK"] = "공격대 방어 전담"
L["UNIT_MOUSEOVER"] = "마우스를 올린 대상"
L["UNIT_NONE_DESC"] = "현재 선택된 대상이 있더라도 항상 새로운 대상을 지정합니다. 또한 자신에게 자동 시전 기능이 적용되지 않습니다."
L["UNIT_NONE"] = "대상 없음"
L["UNIT_PET"] = "소환수"
L["UNIT_PLAYER"] = "플레이어"
L["UNIT_ROLE_DESC"] = "방어 전담, 치유 전담, 공격대 방어 전담 또는 공격대 지원공격 전담이 선택된 경우 파티/공격대 내에 해당 역할 전담이 한 명만 존재해야 작동합니다."
L["UNIT_TANK"] = "방어 전담"
L["UNIT_TARGET"] = "대상"
L["UNITFRAME_OPTIONS"] = "개체창 설정"
L["UNITFRAME_TRIGGER_ON_MOUSE_DOWN_DESC"] = "개체창에 마우스를 누르는 순간을 클릭으로 간주합니다. 기본값은 마우스를 눌렀다가 떼는 순간입니다."
L["UNITFRAME_TRIGGER_ON_MOUSE_DOWN"] = "마우스를 누르는 순간 클릭"
L["UNNAMED_ACTION"] = "(이름 없음)"
L["WARNING_MESSAGE_CLIQUE_DETECTED"] = "Clique를 사용 중이기 때문에 이 애드온의 일부 기능은 작동하지 않습니다."
