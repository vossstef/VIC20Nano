--Copyright (C)2014-2024 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: IP file
--Tool Version: V1.9.9.01 (64-bit)
--Part Number: GW2AR-LV18QN88C8/I7
--Device: GW2AR-18
--Device Version: C
--Created Time: Wed Feb 28 23:51:28 2024

library IEEE;
use IEEE.std_logic_1164.all;

entity Gowin_pROM_kernal is
    port (
        dout: out std_logic_vector(7 downto 0);
        clk: in std_logic;
        oce: in std_logic;
        ce: in std_logic;
        reset: in std_logic;
        ad: in std_logic_vector(12 downto 0)
    );
end Gowin_pROM_kernal;

architecture Behavioral of Gowin_pROM_kernal is

    signal prom_inst_0_dout_w: std_logic_vector(29 downto 0);
    signal prom_inst_1_dout_w: std_logic_vector(29 downto 0);
    signal prom_inst_2_dout_w: std_logic_vector(29 downto 0);
    signal prom_inst_3_dout_w: std_logic_vector(29 downto 0);
    signal gw_gnd: std_logic;
    signal prom_inst_0_AD_i: std_logic_vector(13 downto 0);
    signal prom_inst_0_DO_o: std_logic_vector(31 downto 0);
    signal prom_inst_1_AD_i: std_logic_vector(13 downto 0);
    signal prom_inst_1_DO_o: std_logic_vector(31 downto 0);
    signal prom_inst_2_AD_i: std_logic_vector(13 downto 0);
    signal prom_inst_2_DO_o: std_logic_vector(31 downto 0);
    signal prom_inst_3_AD_i: std_logic_vector(13 downto 0);
    signal prom_inst_3_DO_o: std_logic_vector(31 downto 0);

    --component declaration
    component pROM
        generic (
            READ_MODE: in bit :='0';
            BIT_WIDTH: in integer := 1;
            RESET_MODE: in string := "SYNC";
            INIT_RAM_00: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_01: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_02: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_03: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_04: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_05: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_06: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_07: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_08: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_09: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0A: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0B: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0C: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0D: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0E: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0F: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_10: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_11: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_12: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_13: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_14: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_15: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_16: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_17: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_18: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_19: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1A: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1B: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1C: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1D: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1E: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1F: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_20: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_21: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_22: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_23: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_24: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_25: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_26: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_27: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_28: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_29: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2A: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2B: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2C: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2D: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2E: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2F: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_30: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_31: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_32: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_33: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_34: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_35: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_36: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_37: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_38: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_39: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3A: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3B: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3C: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3D: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3E: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3F: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000"
        );
        port (
            DO: out std_logic_vector(31 downto 0);
            CLK: in std_logic;
            OCE: in std_logic;
            CE: in std_logic;
            RESET: in std_logic;
            AD: in std_logic_vector(13 downto 0)
        );
    end component;

begin
    gw_gnd <= '0';

    prom_inst_0_AD_i <= ad(12 downto 0) & gw_gnd;
    dout(1 downto 0) <= prom_inst_0_DO_o(1 downto 0) ;
    prom_inst_0_dout_w(29 downto 0) <= prom_inst_0_DO_o(31 downto 2) ;
    prom_inst_1_AD_i <= ad(12 downto 0) & gw_gnd;
    dout(3 downto 2) <= prom_inst_1_DO_o(1 downto 0) ;
    prom_inst_1_dout_w(29 downto 0) <= prom_inst_1_DO_o(31 downto 2) ;
    prom_inst_2_AD_i <= ad(12 downto 0) & gw_gnd;
    dout(5 downto 4) <= prom_inst_2_DO_o(1 downto 0) ;
    prom_inst_2_dout_w(29 downto 0) <= prom_inst_2_DO_o(31 downto 2) ;
    prom_inst_3_AD_i <= ad(12 downto 0) & gw_gnd;
    dout(7 downto 6) <= prom_inst_3_DO_o(1 downto 0) ;
    prom_inst_3_dout_w(29 downto 0) <= prom_inst_3_DO_o(31 downto 2) ;

    prom_inst_0: pROM
        generic map (
            READ_MODE => '0',
            BIT_WIDTH => 2,
            RESET_MODE => "SYNC",
            INIT_RAM_00 => X"C85114858216A01357C8580348837885243448C1C0C1949151585314D020C153",
            INIT_RAM_01 => X"CE0C1C038C5115912D1EA5963036009E034059364064990CAF030C2408403804",
            INIT_RAM_02 => X"F0A27340E952445130D8650F4E36C400E36C4F4D17C600C08E00D08F00E0CA8A",
            INIT_RAM_03 => X"B386252CE1814B20B3806D0488F168330A08A18E3261A274C64DF0E307264CC1",
            INIT_RAM_04 => X"CD1000F2A24032174CAB18B2CE16894B381314294B38069B8A341C3049008138",
            INIT_RAM_05 => X"DF51CF2DA100EB7AD683C099264780D302A091E0081C30323709D94911090234",
            INIT_RAM_06 => X"0C0C007ABD0A4A8366D005F8BC00F6277ECC300217140337C41C5170C26B7359",
            INIT_RAM_07 => X"3B400E0ED00EC0A649661D11DD0B7D20D4985C585811112F0104C18987A280B8",
            INIT_RAM_08 => X"FFB1C0028D1C0CB137AB390C86A8A3761B2AB15A34620E015411B4DE02400D0A",
            INIT_RAM_09 => X"FFFFFFFFFFFFFFFFFFFE04C328D19D0AC62075D111444751FFFFFFFFFFFFFFFF",
            INIT_RAM_0A => X"29297700124484184546D1A6619661DB476512491098451A585C329CCAC32842",
            INIT_RAM_0B => X"302E90D32919E002920B612B0CBD74946754705824841555987542D90136A302",
            INIT_RAM_0C => X"018CEDDAAAAAAAAAAA9710482207660134A450CA000C3054101732A5DA1835C9",
            INIT_RAM_0D => X"0CA637357880082810A24A8A0863849151090D89D08D5E332A319447020E1802",
            INIT_RAM_0E => X"2081B30AC8363404040C503370440B4311CA903A28D132A84B1565C66AA53329",
            INIT_RAM_0F => X"51880C0D09A805A241160C032910C20C55337626CC24DA54710D34514A3003CD",
            INIT_RAM_10 => X"2A16C14280B6951CC34D145284603330055307080C59306AAA6376AAAAAAAAAA",
            INIT_RAM_11 => X"D52288A4CD1280CE2E22728154CC2990606072360D20C00421744251C8D0936B",
            INIT_RAM_12 => X"D245056943E940E971425CA970F2903E943E943E96DEE310A80815E2A3288A4C",
            INIT_RAM_13 => X"53122B14A04524D2A100A0C11D255476A817477205188D529028916422829AB8",
            INIT_RAM_14 => X"53475646810D9514A161D04524D38A4A46136721A48A0451088A2E349141E2AA",
            INIT_RAM_15 => X"25100C176819AADDA27916EEC514641E011D9D5365C285904355468A10987555",
            INIT_RAM_16 => X"03125CB31232440C89650D055228555291590466316470251080438471854505",
            INIT_RAM_17 => X"AAAAAAAAAA258A436511DA2D892A8CA244C022C08BB224811414040535228D88",
            INIT_RAM_18 => X"8728772C4616F0DDD755575327032C24D526AAAAAAAAAAAAAAAAA9018CAA1645",
            INIT_RAM_19 => X"729759407EEF09DDCD08BAD167CB966E1CA1D4B1105BC77773422E3459B2E59B",
            INIT_RAM_1A => X"FF76FFCFFFFF41651512597717259460601455C9805167273022E1379D3A5BC4",
            INIT_RAM_1B => X"21991CC00000A8FFAB7FFFFFFFFFFFFFFFFFFFFFFBBFB0334E2C3FF97FE5BFC7",
            INIT_RAM_1C => X"8281D754748888888880CC1220038034745DC3340538A4E20040412222222222",
            INIT_RAM_1D => X"D17740524108400C2309042051DD760540A3410C88C15551C646751AAC00C111",
            INIT_RAM_1E => X"70C113192075D292075D5146A07012494500230555540C2305100C24BA920D35",
            INIT_RAM_1F => X"546110CA1CE28484502C2CB4A4500080451A095690AB30441555111944455100",
            INIT_RAM_20 => X"292C880B05CD1915647056B6348AEDDD442862A24B058646DB4412695CA24289",
            INIT_RAM_21 => X"18528C90A008444119471041661109CA19E0124CB6D90411708CDD8480740812",
            INIT_RAM_22 => X"CBA4F50645059064048B62C80205906450514551C613109010A15E1915694651",
            INIT_RAM_23 => X"C124143038D11447D09E796664E67791C510B14082F63D8442C503D84B8E4E5D",
            INIT_RAM_24 => X"3640C14934050109091403083A20EAA05120220EC90B054536C599DC50C73025",
            INIT_RAM_25 => X"8D2C858205D30198C908D89F30CF023848E01820099824260C82008922600380",
            INIT_RAM_26 => X"441911946595E0498CDC92F0230E302832445B20980603253370C9F30CF3880A",
            INIT_RAM_27 => X"C4C3238445966D194095228442596DB6594000A28D3C5C958320112355091112",
            INIT_RAM_28 => X"070C000F3C003236C8033578C10CC9C112362D995456512E320B4CF34C2146A8",
            INIT_RAM_29 => X"2F4B9A0DB623200B7632C04651664308C20D00DE0106015B24301424990C04DF",
            INIT_RAM_2A => X"A19D28582445103CCC84DE32447700EB04681278041925A61B48C914A1A44944",
            INIT_RAM_2B => X"44804633C48C3136C0038C104C9F228A303A2A4A04240320A1B4B33411513744",
            INIT_RAM_2C => X"551B29848D4230E340318C4D60214CA0128915DD127609890A527314064D944C",
            INIT_RAM_2D => X"300413243080756C944C11C01A3348061481601E0205B27013CCC55C4DE32789",
            INIT_RAM_2E => X"509C0C95006901A4141D7698A34655642868A29184C503C58954223C9A157B04",
            INIT_RAM_2F => X"91C24D1498124084389463112410D0505900D00340E0418840C0504D24504D24",
            INIT_RAM_30 => X"C9CD0C80C44F0D1924458423282453490235408EA9CD0C880C27499264952670",
            INIT_RAM_31 => X"50658C2100CD1012A47644644C000D11C84301CC70588031C6300C02284008EA",
            INIT_RAM_32 => X"45469A6900554128588440330D1CC114155CC35845424338511547C99321D6DC",
            INIT_RAM_33 => X"51995D1A1905060C511C51901444B3A4C285504169A651442685113160555915",
            INIT_RAM_34 => X"41252854D64D0109E14AEE4E81DDB2707162CC9120B3278CD529034471401E41",
            INIT_RAM_35 => X"8914A9D40316D494504E244281CA8172376254A1F389515D6444516459191189",
            INIT_RAM_36 => X"C983041737BB155844523BCA044555A886C99501500D4BB4C53C1A0616244347",
            INIT_RAM_37 => X"14564486065174447441559E28145D851CDD1C0E0CC9C90EA8AA461C15135281",
            INIT_RAM_38 => X"42175921445188A6E2853CC8DE6E3755557054438464D1144452CD1860418051",
            INIT_RAM_39 => X"1570C0C6DD52191D14759D40119B809E0CA0EF33B3C18302D1432B855DC73754",
            INIT_RAM_3A => X"ABF6F8A6AC431DD8C7038466C44B0D458010518500C708E1A08D591046513567",
            INIT_RAM_3B => X"9675ACC1C7017699C484699B20804406848D92A1A4497572B090C6118656BD72",
            INIT_RAM_3C => X"0BA0BA09411152D1B72644A103B45451964746670789E2789AE68919465D1745",
            INIT_RAM_3D => X"3C64451590199D0592105184D30508C7326641502300585156055594A26A2682",
            INIT_RAM_3E => X"30518082306CBADD0A0802899D11157D479A0DB506E08645695519651D54506E",
            INIT_RAM_3F => X"E69FF418530C38C30F24638C38C38C38920B20B30A20D2CE28B28828718FFF0E"
        )
        port map (
            DO => prom_inst_0_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            AD => prom_inst_0_AD_i
        );

    prom_inst_1: pROM
        generic map (
            READ_MODE => '0',
            BIT_WIDTH => 2,
            RESET_MODE => "SYNC",
            INIT_RAM_00 => X"41181A11A044428542411AC188A1A81128B484C6D20154A44652280A5F240A1F",
            INIT_RAM_01 => X"359429C22412115251511515903A80A802835084214210411C0138128961143A",
            INIT_RAM_02 => X"D322534D99024B2138ADD003E3CF3E1E3CF3E3E2894E00D04D0CE00F08C17C09",
            INIT_RAM_03 => X"23B9A300E240C00403800F0874C24423011771BB01B770A57C4ED0BC190A5702",
            INIT_RAM_04 => X"0D2F3C9340BC903BF1143C200E2668C038802424C03800A5C33C2ED08F0A021F",
            INIT_RAM_05 => X"D12A699B9500CB82E0BAF0E2054A0060030812A030ED02901B41E185A325801A",
            INIT_RAM_06 => X"4118000AB4FE93E0E27C5C8F9FC32578C18DC280390A002AC8E42874094B89D4",
            INIT_RAM_07 => X"26205195E2D9F2583CF09192128847C510A5502110A15E87028AC28A8E4257A1",
            INIT_RAM_08 => X"FF5D0979812F04837E3559D18EA81080302A835105817B12BCD9A65B1198D934",
            INIT_RAM_09 => X"FFFFFFFFFFFFFFFFFFF3CA081BD5D18979283CF0F23C3F8FFFFFFFFFFFFFFFFF",
            INIT_RAM_0A => X"2B12782281A98A22F778B61D8F2E83A3FB4320C32822C72AE2D8055415411000",
            INIT_RAM_0B => X"3407DCD903D540A95161CB01C4BFCC24A49360549A49987F12CA5216A2455442",
            INIT_RAM_0C => X"42055E5AAAAAAAAAAA80406A82246412585C9510C2648080563B121F35A009C8",
            INIT_RAM_0D => X"300E19054682AA509A6201E42481482525822E0E5AA5E4002502784925812045",
            INIT_RAM_0E => X"12C66C25763839080AB0E8C1444AA960554592851412816F88255BB995591116",
            INIT_RAM_0F => X"CE07E0814658C559AB09F10816161A24E4009409B05C01C0B16082082806A1F7",
            INIT_RAM_10 => X"1509B2497E40702C1820820A05B1110508151B16B0E5C0AAAB83BAAAAAAAAAAA",
            INIT_RAM_11 => X"1641449A41247E0155905D5264049673809F7109F71F1A888394909148146855",
            INIT_RAM_12 => X"DB6DB7D554000057A800C8FBA877FFEAAA95554001CFFFD01C892341411449A4",
            INIT_RAM_13 => X"92310626536DB6D9562CA08836B830E855274B7129209E90B3249DFF12C86572",
            INIT_RAM_14 => X"F358B7760120C0C4B34B236DB6D9C1CA4827A7052C89277FCC1B24B6DB6D7D61",
            INIT_RAM_15 => X"08F10823E82D1C708374007D1D64D8DE05621110201A0D2848080A0B1012CA47",
            INIT_RAM_16 => X"C116493F03B280A903CF82C649240C385E5E00FB3030E40F22AA1EC3C0FE3F06",
            INIT_RAM_17 => X"AAAAAAAAA903C3F08F03658742D6CC3CF59C94B442E0F43D093A0B1A3A10BE43",
            INIT_RAM_18 => X"83F60EE51E2877A50CEECCEFFCCFF9D775DEAAAAAAAAAAAAAAAAA64AB3AA1C87",
            INIT_RAM_19 => X"3EF0F571FC436650F3252ED52EA423C20FD83F9470A1DA9438C9473547A904F0",
            INIT_RAM_1A => X"FF0CFFDFFFFD7969298030FA2B030CA29F1C7E8E7C71CA3BCC94B682B86C8DFC",
            INIT_RAM_1B => X"D3D34F800000D7FF3F7FFFFFFFFFFFFFFFFFFFFFF37F3F3CCD483FFB3FC8FFC3",
            INIT_RAM_1C => X"62A0F3D6BC890890890C1D02410B443C3C8FD0390585781A1600B278D278D278",
            INIT_RAM_1D => X"F23FC25B89164528434D18B050FE3F058AE0B22090823CB6053CB8FAAD100611",
            INIT_RAM_1E => X"7C016015283CF59283CF5A45E0BC63B245844108F2C9084345293D2CA2D3CEF8",
            INIT_RAM_1F => X"74B3034878C5488CD05C500D60D4C41C852917768017114823CB60F23C3F8F29",
            INIT_RAM_20 => X"B98B83E2C9C50F293CB24A0C16495995C09C928200CA03C871CB20F5803CF52D",
            INIT_RAM_21 => X"0F88F43E3C84840C320E03823F303248795F024B1C72CB6CA3C095481C922920",
            INIT_RAM_22 => X"0304FB23CA08FC3E083D10B3C808F23CA1830F8383E30324A8879FCF21CB1CB0",
            INIT_RAM_23 => X"FB162482B0E86CDEF1DDDE985C790DE4FD04F23044C4010413C8C010C347A013",
            INIT_RAM_24 => X"0A6242413B2E41200520822816A255E093009005C287E54609F9591892531609",
            INIT_RAM_25 => X"C0F049D2297C02470240249317030B54CD5820AAA0D5800B20CA2AADA0B79139",
            INIT_RAM_26 => X"609D0FE0D8FE0282C0249A308046D06C03449D2298093C08309309317031B41B",
            INIT_RAM_27 => X"09D02424893E4392C82D298488F38308B2A5266980D46829C7C02B33A5F99282",
            INIT_RAM_28 => X"19244C071788921544933A570B1702C5110A0393E4A4B997C2253031F0924A74",
            INIT_RAM_29 => X"AEEBBA0E0CB10120A214703F830D8B445B480C56E907029D26172496020409E5",
            INIT_RAM_2A => X"A1DE3C9D2549271305C825C24484351ECA999256649D0F3CF2C70838872CA2EA",
            INIT_RAM_2B => X"00888401C8889215489170B0B025E18D2074373E0A303068A1B86C3011E43784",
            INIT_RAM_2C => X"111B7438018116C20314444513334DD9A181511D5B46A00048000325142100C0",
            INIT_RAM_2D => X"932C2C08B4C0BA74909D138226130D3130D374D80309D2585130592C825C2431",
            INIT_RAM_2E => X"225F24E121118446060F3C44538684861014106C408D2546429C9014800A4184",
            INIT_RAM_2F => X"02CB6D861CB34A44B004100360642824600C1A084AC0A848D0F2AEB6DB6DB2CB",
            INIT_RAM_30 => X"40D805D0D4C70D21B4A1AC0044861B6DAA26A4CDD0D8C5DD0D8360D806018362",
            INIT_RAM_31 => X"C03CFC82A24969030B774564AC9241128C8A08F03C8788A28123280156C2CDDD",
            INIT_RAM_32 => X"862E8618048461A8440CAAF22C2F507C23E8C870E2E2CB304FEE3E8D2E031CF1",
            INIT_RAM_33 => X"251112A42627163011E4116B0448206F0D810FA1186118B2E102CBB0B21CB871",
            INIT_RAM_34 => X"05DB284621414545DEC8D5410599B1409262C5121C4107709B12005480F85505",
            INIT_RAM_35 => X"092C99E4A0365054580DE4938A8B715279436C8DA37599DD3C94A1554F252945",
            INIT_RAM_36 => X"45593036077503DC0F53767DA0F43DDCDC85524CD0C1C9670C272E1A1624824A",
            INIT_RAM_37 => X"A0CB2C080AD26654868D1D1DF824D90C3899C9083C0D4D85D0B64A38CD906382",
            INIT_RAM_38 => X"0235742308D200D55005A80811DDE64B4B714952889C822778D9C90082736283",
            INIT_RAM_39 => X"7ED3C21CF1E03E0B20D8FEE2916200D9B8889A31420A8E2852E0377D298E1577",
            INIT_RAM_3A => X"8C0849BF2C0860001B146CCC004803FD0398E30F030F2AC3434DDDD83F8F07EC",
            INIT_RAM_3B => X"F3FAEFBBB4109431C02C832ECBC804011005C04045A0D44443120C31895B0C50",
            INIT_RAM_3C => X"70C70D01C111D0721E0A499936541E8763CBC3CB43C0300C03C0C0FE3F8B22C8",
            INIT_RAM_3D => X"F03E1CF5E428FE88F0D8E30CC140C30F30A3E0FAA8B80A80028006800C30C340",
            INIT_RAM_3E => X"C087AAA100224EC2E92AA92CFE2832FB2FBA0E0D0ADC43E2CB2CB2D8B520D0AD",
            INIT_RAM_3F => X"CCEFF4DB5D73CB2D35D74C71C30CF3CBEF3DF7DF7DF7EFFBF3CFFCF7DF3FFC71"
        )
        port map (
            DO => prom_inst_1_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            AD => prom_inst_1_AD_i
        );

    prom_inst_2: pROM
        generic map (
            READ_MODE => '0',
            BIT_WIDTH => 2,
            RESET_MODE => "SYNC",
            INIT_RAM_00 => X"ACC049EE6BB3853A3D2CC609A66992CC9EA0A662796C6D266EC82FC9249610A4",
            INIT_RAM_01 => X"8CC1C5089682CA8288AA88AA6A89AA2688A88B22CA2C8B288FA7DA0E8CDA6099",
            INIT_RAM_02 => X"F99C9F6AA2980A29F6AAA9A02000001A0820808229E0A7EA7CA7CABCABD8C618",
            INIT_RAM_03 => X"8BC28BA2F80AE8A68BE22F8AC1C8A68F29AC08818BA20438C63EFA10A8C38C36",
            INIT_RAM_04 => X"6824924AAA926A9BCAA6868A2F88A2E8BE048882E8BE220168BE2034E3AA1394",
            INIT_RAM_05 => X"78093C866000E409024102299A09A26B88AA424A0AA7866AA9E4C63A484A5AA9",
            INIT_RAM_06 => X"2AA6001AB10F47CEF6F39C1724DF3EDDCF27065A98428AB926E1029E12A40A62",
            INIT_RAM_07 => X"6A52CCCCDB88DB4630C2448242D3636006A006600620425026FBB83CAB878C7A",
            INIT_RAM_08 => X"FF30E8C4E42CAD018C8084C0C2AAD81080AA9004914801AA92AEABE1AB82AAA8",
            INIT_RAM_09 => X"FFFFFFFFFFFFFFFFFFFD0A1EB88282130E8D5169886A619AFFFFFFFFFFFFFFFF",
            INIT_RAM_0A => X"48997B5A05958A0080080200800084A01804241023209000E0AE99A244399A66",
            INIT_RAM_0B => X"8082232FC4028A5434A34F23AD0DAD9090A0BA4D9937992F4009F4464DD9910B",
            INIT_RAM_0C => X"10164E4AAAAAAAAAAA9D9D804C410954A6672441080D061D1840F436F0C9422A",
            INIT_RAM_0D => X"C31AD3D19AE96A436AAAA090D80C82A406189E146AA4288C98C9890942E60316",
            INIT_RAM_0E => X"859480DA0BB8586162410805990841091A2426905A42892CD0DD1A45564B859A",
            INIT_RAM_0F => X"A26922D4164B94699552442890504B85488500520361D096A50D3C51CB90AA4A",
            INIT_RAM_10 => X"D952003691B425A9434F1472E6AAD05061DB535A4108062AA9873AAAAAAAAAAA",
            INIT_RAM_11 => X"46292D193422922440428135EE16982C982498524AA442A35500852629416D93",
            INIT_RAM_12 => X"A28A2BFFFFFFFCF9DFB26659DCF3FBFFFBBBBBBBBA69554602D0E9298D9AD193",
            INIT_RAM_13 => X"B84DB35E6A28A289834D22198E31A63B985A02A5A5017E728AE678BCDAEB0138",
            INIT_RAM_14 => X"FA10AA2AEB4DB5B6AA002A28A28A2E91405F9C79A2B99E2F31EB8628A28A810E",
            INIT_RAM_15 => X"41602325AA02080FB809DC206069092EAC426C6B4566E02AD3496AEB9A4009D2",
            INIT_RAM_16 => X"18C2F2085AD4302010003030F1CD61A2CAC62639F9A6008022AA6A650D6E5848",
            INIT_RAM_17 => X"AAAAAAAAA9C6B0240298E08D30883E00202508029024030B50D0E0D2F0DC2ED0",
            INIT_RAM_18 => X"66850700024555BFFAAAAAA99AA99B323C8EAAAAAAAAAAAAAAAAA21020AA4012",
            INIT_RAM_19 => X"7EF05FAC1AFD6AAAC5EA87144D0103019F141400011559AAB1BFF10513C04080",
            INIT_RAM_1A => X"FF06FFCFFFFE458507A441BA42C4108424412E109104084317AA1BEE36F80EFA",
            INIT_RAM_1B => X"90140040000098FF553FFFFFFFFFFFFFFFFFFFFFF73F5571BFF2FFF3BFC0BFE7",
            INIT_RAM_1C => X"B43545A0A2D2EF2ED2E1A8ACBAAE6AA250168872A4A122AC58EA208E38D34D24",
            INIT_RAM_1D => X"405A294A205B369FBA28AAE2494E5A2415E8A29F2E1A6982586019AAA8AA1A8D",
            INIT_RAM_1E => X"A236AA63CD516A34D516825AE8A2AAC23A5FB869A60AADBA282E88AD088A6E99",
            INIT_RAM_1F => X"30955A1061EE9B9BEDE5C91B01E7771AACA0F33004B3CFAFA69829806A639A96",
            INIT_RAM_20 => X"6A04B101A89A94A851A6881AEA2A888A3F89A80431A8A508411A286CF7106C1B",
            INIT_RAM_21 => X"56D04F101A76F359405BD6DE5955629064D2F6B410428A28A6B38AFF1AB760C8",
            INIT_RAM_22 => X"A45220A51B6963588A1BCC41A7F96951BC965396F59F562B29064A1425065068",
            INIT_RAM_23 => X"0EC85A7636E3F160081000411201100000460906A10194511824194524200104",
            INIT_RAM_24 => X"4189F03CA492369FF827C87298AA68E884F61F64F0F8019042006061696C9142",
            INIT_RAM_25 => X"2C261E9A94C0EBB4107707EDB03CA59BA44A21AA9D683488FA1C8404AC288608",
            INIT_RAM_26 => X"83EF94A5094EFA903707E0DA4F6C25888621E9A94BAEF041CC341EDB03CB0962",
            INIT_RAM_27 => X"3688D890AC2F0BC1ED15C610A492C92C51D9D92B6F3A218EB8362C9CBBCCC20F",
            INIT_RAM_28 => X"89FEF1BEB0B5E8FB2FD94BB43CB0101D85C1C9E272385E6F049B01CB01E9092E",
            INIT_RAM_29 => X"2DE37812184EB4017CF042529450A62DC2AF23EC285A2CE9BAFAFA61D2238EEE",
            INIT_RAM_2A => X"0689A2E9BB6CABB41E9F0D079090E00F3BCC07B301EF841841B431A10610A109",
            INIT_RAM_2B => X"721D99DFA771E8FB2BDB43CBC10C376B85A86A6E98E48D8B06A6C07A46E8A263",
            INIT_RAM_2C => X"303A2386362B70DBC8FBA67EE895AAA6CBA0202826086F2F2BCBCA78C3C0F252",
            INIT_RAM_2D => X"F872F042628A2BA6E7E8A76B2D87AAADF6AAAAAD8A2E9BBADB41ECA5F0D078E0",
            INIT_RAM_2E => X"2A0C81C69888EAAB93586A2204A9A8ABA1A1A2D3A6D69BA232E3E9FA084B8BAB",
            INIT_RAM_2F => X"DAE28A0825C921D436F2EA95A903030B0F2B4B21AEDB0BA162C828A28A28A28A",
            INIT_RAM_30 => X"9D6F7C42427EA82060903283BA420A28AEA2B6966D6F3C6424368DA348D235B4",
            INIT_RAM_31 => X"BA618E2AEFE86D9489113320B7DB64425AFEA56158B8ADEB2E99FA82AB299666",
            INIT_RAM_32 => X"D46AB2C8F8B39E43B220ABC85EB8F96B26B274429634D3B8140E5B6C2F881841",
            INIT_RAM_33 => X"0A46E6E0E961FB81CEA7CEA9F3B89EB8363C6B9EE38CE5862CD69A79A961A18E",
            INIT_RAM_34 => X"5E6DA3BB6C1A3E36D366E4387E443D050EA41642EB0CDB416DA8F6A095A7E4B8",
            INIT_RAM_35 => X"6825882754F8ADEDE5FD2087A21387968A0FB664DB4C8ACE60B08F1B182428B6",
            INIT_RAM_36 => X"3EC1E4B8D99A41A906BD9B04A0681A6D6E3EC239E236B2B41DB42E88F8609E0B",
            INIT_RAM_37 => X"069860B868EA1220A0A8282D3AA3CADDB688B82DB2BC9638C33A0B769E8587A6",
            INIT_RAM_38 => X"C8F1A94765C012E8427A76DFA8CD110B038E0297A5A5F86B49AA9F8996BEB898",
            INIT_RAM_39 => X"4EDF2A10610CAF9826398ECB060B6FEA7E258D9627EE9FB286C8734C06DD9132",
            INIT_RAM_3A => X"F3F3333B6ED051331D801EA032D061CC8266FB6CA21F97EA86AAAAAE501684EC",
            INIT_RAM_3B => X"853B2F3B888510021D01806F006389822FB6D88480A010330BB604118B337BFF",
            INIT_RAM_3C => X"00020860244648421843ACCCB3326098A60A250A2509426098E5098653942609",
            INIT_RAM_3D => X"2A52594C27214E0160A6FB69EBE5A21F9CA58561006E11844611168E00008218",
            INIT_RAM_3E => X"8D83C403012310347A2AA8194A8965375378121AD8D3E525065941996825AE8D",
            INIT_RAM_3F => X"FEEFF82083C28A2B8E3CC0A28A286186C34D24920B28938930F20838D34FFC61"
        )
        port map (
            DO => prom_inst_2_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            AD => prom_inst_2_AD_i
        );

    prom_inst_3: pROM
        generic map (
            READ_MODE => '0',
            BIT_WIDTH => 2,
            RESET_MODE => "SYNC",
            INIT_RAM_00 => X"466C8466C199CED99BC66C49B4C1BC667858B4EEE3466CD9998933E42F3C2B6C",
            INIT_RAM_01 => X"5223FF4ABC6A666266666666D3AB0EAE0ABD62D8898B62222F0C30184527DC9B",
            INIT_RAM_02 => X"E08C9BC222F08826BC222F1090820804082090967BCE1EF1EF1EF1EF1EF3123B",
            INIT_RAM_03 => X"C396AF30E18BCC34C3822E0BDEF1B04BCC35E31C39888CDB1238E1C798CDB130",
            INIT_RAM_04 => X"462F30C1BBB0D3BB922E38C30E19ABCC3888D89BCC38229B8C382C7C4F153139",
            INIT_RAM_05 => X"C226BC2038006C6B1B97126F098B826F09B422F35EEE01D3BB82D206D016D3BB",
            INIT_RAM_06 => X"0E34008A9ED49961579547DDD04B9EC7A91E41D3B8ADD38B0EA2B5B805AC636B",
            INIT_RAM_07 => X"CCA22222E022E02238E2226262CDBA222EA22EA22E62665D9F0CF323D9CDF5BB",
            INIT_RAM_08 => X"FFD70F57422F1CC2D8BBF37B000011551500205515535C38BC328C2C38B0224C",
            INIT_RAM_09 => X"FFFFFFFFFFFFFFFFFFFE492F35AEAE3B5A5F8E2620898B22FFFFFFFFFFFFFFFF",
            INIT_RAM_0A => X"3E0BBBCFC84E8A82BB88A2288A288AE2BB8A28A0A302A280C2B87BB8EE2489A2",
            INIT_RAM_0B => X"388AE3E7CAEED11BFFF186219FEEF8A8A8B9E1ECC40ECBBEE203B3E103BBBB8B",
            INIT_RAM_0C => X"280CC0EFFFFFFFFFFFFBAF9998BFB8CFF0E0EEE28BBF8CFBBBCFFF1BEE48EFCE",
            INIT_RAM_0D => X"D328DCBFBFC519D3E9F382BCFA0F912E1E334E3FE99E2D0CE8CE8B88FF8F413E",
            INIT_RAM_0E => X"0E33F4FBDE00F09C8FD33C43BB899B97BB8EED78F9E2F3F5FC3B875DCEFD08FB",
            INIT_RAM_0F => X"C70F7CFE23FFEFF860CFDE2F3CBEEF333E0CF8CFD3E4E2B8BFFEBBEBBE3AF39C",
            INIT_RAM_10 => X"F8CFD43EF7F8AE2FFBBEBBEB8EF0DCFCCFB8CCFBD33F48FFFD8DD3FFFFFFFFFF",
            INIT_RAM_11 => X"F227DFC43F22F7CEEEE2E7B3B433FB71C23DD0CFDC3DEBC38CF88CCF80E233BC",
            INIT_RAM_12 => X"A69A6B77777777677667777FFFEAEEEEEEEEEEEEEEEE0A0929CCF327CCF9FC43",
            INIT_RAM_13 => X"D08CFB3BE69A69A7BBEFF2322E3E28BBFF3BA3BCFE80E4E2E334EAF88F4FFFF9",
            INIT_RAM_14 => X"E6A02AAB872EAEA2D288069A69A70EFFA03938BCB8CD3ABE32FD3269A69AC7FE",
            INIT_RAM_15 => X"C22E2348B89E28AEE3BCB8ADEE23F3EF1E80EEE7AEEB8E29CB8B8B8D09E203BB",
            INIT_RAM_16 => X"88FEEE27E03F27DE02883323E49F8E22EEE628B9FE28B98A25998308860C88F8",
            INIT_RAM_17 => X"FFFFFFFFFD0AF2CCCA62EEC622FA3F28AEE0B8A232CCB328CCCCCCCCDD408432",
            INIT_RAM_18 => X"40150055405551000EDDCEDEDEFEDD7B6EDAFFFFFFFFFFFFFFFFF22335FF8862",
            INIT_RAM_19 => X"82A29AA8BAA9A800EB002EFFE1FF20FFA0FCA7FF2FFF6B003800095558154815",
            INIT_RAM_1A => X"FF2BFFCFFFFF13BE8EF0A21BCF0A228CFD8A0E3BF62808CFAC00BAAA86A882AA",
            INIT_RAM_1B => X"00545500000C00FFA23FFFFFFFFFFFFFFFFFFFFFF33F08BAFFFBBFFBFFC8FFEB",
            INIT_RAM_1C => X"497E38A8B8E78E78E7808E19E3878E388A22E0CF8A66749021D004FA9503FA95",
            INIT_RAM_1D => X"288B84A744E4085EE38F3874A6248B4A61D08A5E78308A22FB88322FFE383E0A",
            INIT_RAM_1E => X"B03AE3EF9F8E2979F8E2A2FBD1B0E3923A2EE0C2288B8EE38A279E2FCAF3021A",
            INIT_RAM_1F => X"A8842024AFEBDDFFAFBFBC2AF3A103209A08EEA6C8A41E9F08A22620898B2246",
            INIT_RAM_20 => X"AA8A32F29AFA622A8ABE4829EAD99A9A03B3A7C732089898A20864BAE32CAA2A",
            INIT_RAM_21 => X"60E8AF2F2930C182208B60F088C20224AAE7FEB528822820A4939A8B20BBF4CC",
            INIT_RAM_22 => X"855444588BD22389492F8CB293C2248ABC228B22D80E2023024AAF62E88A88A4",
            INIT_RAM_23 => X"D5F8E930FC4360894955355552555355535451540555155D5145515525655554",
            INIT_RAM_24 => X"CE94F32C31423A4AFA22F0F86A65ABD18CB44B4A332D7BB8CF5EEEE3A4AD28CF",
            INIT_RAM_25 => X"CC7C0AC24AE4DEB1332333AF393F12ABCAA522664AAAE888BC3E199A4CFD4B54",
            INIT_RAM_26 => X"B3ED22E88A26E1336737A6F10FCE722F0FC0AC24AF7AE4CC8CF93AF393F39C8B",
            INIT_RAM_27 => X"2BC0ACA89A1A86A19F1C3AA89061861861A8EEE7CE7C237A2F782D0C2B1EE2CF",
            INIT_RAM_28 => X"08B8E23E3932D0EB42E0C2B92D3D336E09CDC6A1A9286ABD48EB93F393A68ABC",
            INIT_RAM_29 => X"4DA3683028AC3CF2A8ECA28BA288930FBFCA23AE542BCCAC28E8292AA2237AAF",
            INIT_RAM_2A => X"5AAC3CAC2B8A6E393A6F3E4EA8A81EED78EE8FBBA3ED0A28A2B122224A2852B6",
            INIT_RAM_2B => X"33702B9F8E72D0EB46E392D3933E5BCF362CEE8D08EC8EAE5AB0F4FCA8EF2B06",
            INIT_RAM_2C => X"2E2AABD63A67EFF288EBC23AF0829AA0F34EEEEADAB62B2A2ACA8BE8BABEA2F3",
            INIT_RAM_2D => X"E2B4E4CD30F332B0A08C3F042F0FCF28B0F2BCAF0BCAC2B0E393AA66F3E4E81E",
            INIT_RAM_2E => X"24EF03FA5AAA6AA96BE38AAA89E8E8E8B3B3B2D7C6CA43C230A2F0BC88C28B02",
            INIT_RAM_2F => X"A2A69A79E6D298F3FCA2F1822F3333333A22A7C691F017C182F1208208208208",
            INIT_RAM_30 => X"FBAA3BA2A22E1A1EAB4EB44EA9B9E69A6F29B4FBBAAA3BAA2AEABAAEBBAEEABE",
            INIT_RAM_31 => X"B48A262A5B8A2D0CAAAAAAA892E34AA2F2FE120381BD6FE34F08F87EAF44FABB",
            INIT_RAM_32 => X"E38A208020AA4902A92894F0CF31C22F48B4303298BFFBBBA20C8BCA2F0A08A0",
            INIT_RAM_33 => X"1AA9B32CACE8EB52B912B91CAE4482B93A6B804A965ABA28AAF8E3BA258A1A29",
            INIT_RAM_34 => X"3ABD226CA98A3A3AD74E9DCBFAA9AAB8F2AE3FA2B2C0EB5FAD2B02A88603AE3A",
            INIT_RAM_35 => X"CA6FBA020829AFAFA31D688F423E8E820A8EB4EAF35A8AAA89A88EAAA2EA2A3A",
            INIT_RAM_36 => X"3AACECA8EAECC3A30E8EEB9AF0A82AA2B27AA23BA23A3EB92C392D08EBEABE8B",
            INIT_RAM_37 => X"18A288A899A6AAA8A89AEAED74239AEC30A9AA2F3C3A3A3BA0EAA8F0AA8E8F42",
            INIT_RAM_38 => X"8BABAECB0FA833ABE23A7CC3AB9D6A42868E868FC3B3F0EB90AB3F088E824422",
            INIT_RAM_39 => X"2FAFC408A08CAC2268BA26C12E8BC3AB7C2CBF3EFFC6FF12A6C0EF5A1ABC3B6A",
            INIT_RAM_3A => X"73F3F73BF9C82EE208BB8E6FC5FCE3D8B170F34E213C39E6CEDBABA1882242F8",
            INIT_RAM_3B => X"289BBB3BDF38E8AEEF288A2D4A22323EEE3AE3CFF8A2ABAA88BF08228BB7FFF7",
            INIT_RAM_3C => X"A28A28929A8AA4A228CE9AAA6AA989A228BB88AB888A2A88A2E88A2E8BA2689A",
            INIT_RAM_3D => X"78898A28E34A26622C70F343F308213C0C2812266415E88FF93FE6B928A28A24",
            INIT_RAM_3E => X"4C0299902310302113599A2A2C0628B68B683028C2D70898898A224E2A088C2D",
            INIT_RAM_3F => X"DCEFFC71C71041075D75D41041041041D75D71C71F7DC75C79D7DF75D75FFC10"
        )
        port map (
            DO => prom_inst_3_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            AD => prom_inst_3_AD_i
        );

end Behavioral; --Gowin_pROM_kernal
