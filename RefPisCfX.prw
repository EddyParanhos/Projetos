#INCLUDE 'RWMAKE.CH'
#INCLUDE "Topconn.ch"
#INCLUDE "TBICONN.ch"
#INCLUDE "Protheus.ch"
#INCLUDE "REPORT.CH"

/*--------------------------------------------------------------------*
| Func:  RefPisCfx                                                    |
| Autor: Edmar Paranhos                                               |
| Data:  28/02/2024                                                   |
| Desc:  Atualiza Valores PIS/COFINS.                                 |
| Obs.:  .                                                            |
*---------------------------------------------------------------------*/

User Function RefPisCfx()

	Local aPergs   := {}
	Private aRet   := {}
	Private oBrwMrkNF
	Private nRec   := ''

	aAdd( aPergs,{1,"Data Emis. De."  ,Ctod(Space(8)),"","","","",50,.T.}) 
	aAdd( aPergs,{1,"Data Emis. Até."  ,Ctod(Space(8)),"","","","",50,.T.}) 
    aAdd( aPergs,{2,"Movimento?","Saidas",{"Entradas", "Saidas" },40,"",.T.})


	If ParamBox(aPergs ,"PIS/COFINS",aRet)

		FWMsgRun(, {|oSay|U_AtuPCZX(oSay) }, "Atualizando PIS/COFINS.", "Aguarde...")

	Endif

	MsgInfo("Atualização executada com Sucesso!")

Return

/*--------------------------------------------------------------------*
| Func:  AtuPCZX()                                                    |
| Autor: Edmar Paranhos                                               |
| Data:  28/02/2024                                                   |
| Desc:  Executa a atualização via Reclock.                           |
| Obs.:  .                                                            |
*---------------------------------------------------------------------*/

User Function AtuPCZX()

Local cQryPCX := ""
Local cQryNCM := ""
Local cQryEnt := ""
Local cQryCST := ""
Local cQryTRB := ""
Local cQryNTR := ""
Local cQryEXP := ""

If aRet[3] == "Saidas"

//----------------------------------Atualiza o SFT por NCM/CFOP(Não Tributadas)-------------------------------------//

/*
    If Select("TMPNTR") > 0
        dbSelectArea("TMPNTR")
        dbCloseArea()
    EndIf


        cQryNTR := "SELECT SFT.R_E_C_N_O_ RECFT, FT_ENTRADA, FT_FILIAL, FT_NFISCAL, FT_SERIE, FT_ITEM,  FT_TOTAL, FT_CFOP, FT_POSIPI, FT_VALCONT, FT_BASEPIS, FT_BASECOF, FT_ALIQPIS, FT_ALIQCOF, FT_VALPIS, FT_VALCOF, FT_CSTPIS,  FT_CSTCOF, FT_ESPECIE "+ CRLF 
        cQryNTR += " FROM "+RetSqlName("SFT")+" SFT "+ CRLF
        //'21011110','21011190','21011200','21012010','21012020'
        //cQryNTR += " WHERE FT_POSIPI IN('21011110','21011190','21011200','21012010','21012020')"+ CRLF //CST 04
        cQryNTR += " WHERE FT_POSIPI IN('04079000','08025200','09012100','09019000','19022000','22011000','22021000','22030000','22041010')"+ CRLF //CST 06
        cQryNTR += " AND FT_ENTRADA >= '"+DTOS(aRet[1])+"' "+ CRLF
        cQryNTR += " AND FT_ENTRADA <= '"+DTOS(aRet[2])+"' "+ CRLF
        //cQryNTR += " AND FT_ALIQPIS <> 0"+ CRLF
        cQryNTR += " AND FT_TIPOMOV = 'S'"+ CRLF
        cQryNTR += " AND D_E_L_E_T_=''"+ CRLF
        cQryNTR += " ORDER BY FT_ENTRADA, FT_FILIAL "+ CRLF

        cQryNTR := ChangeQuery(cQryNTR)
        Conout(cQryNTR)
        MpSysOpenQuery(cQryNTR,"TMPNTR")

    While TMPNTR-> (!Eof())
        
        DbSelectArea("SFT")
        SFT-> (DBSETORDER(1))
        SFT-> (DBGOTO( TMPNTR->RECFT))
        
        //Atualiza a SFT
        SFT-> ( RecLock("SFT", .F.))

        SFT->FT_BASEPIS := TMPNTR->FT_VALCONT
        SFT->FT_BASECOF := TMPNTR->FT_VALCONT
            
        SFT->FT_ALIQPIS := 0.00
        SFT->FT_ALIQCOF := 0.00

        SFT->FT_CSTPIS := "06"
        SFT->FT_CSTCOF := "06"

        SFT->FT_VALPIS := 0.00
        SFT->FT_VALCOF := 0.00


        SFT->(MSUnlock())

        TMPNTR->(DBSKIP())
        
    Enddo

    TMPNTR-> ( dbCloseArea())

//----------------------------------Atualiza o SFT Exportação (Ñ Tributadas)-------------------------------------//

    If Select("TMPEXP") > 0
        dbSelectArea("TMPEXP")
        dbCloseArea()
    EndIf


        cQryEXP := "SELECT SFT.R_E_C_N_O_ RECFT, FT_ENTRADA, FT_FILIAL, FT_NFISCAL, FT_SERIE, FT_ITEM,  FT_TOTAL, FT_CFOP, FT_POSIPI, FT_VALCONT, FT_BASEPIS, FT_BASECOF, FT_ALIQPIS, FT_ALIQCOF, FT_VALPIS, FT_VALCOF, FT_CSTPIS,  FT_CSTCOF, FT_ESPECIE "+ CRLF 
        cQryEXP += " FROM "+RetSqlName("SFT")+" SFT "+ CRLF
        cQryEXP += " WHERE SUBSTRING(FT_CFOP,1,1) = '7'
        cQryEXP += " AND FT_ENTRADA >= '"+DTOS(aRet[1])+"' "+ CRLF
        cQryEXP += " AND FT_ENTRADA <= '"+DTOS(aRet[2])+"' "+ CRLF
        cQryEXP += " AND FT_TIPOMOV = 'S'"+ CRLF
        cQryEXP += " AND FT_ESTADO = 'EX'"+ CRLF
        cQryEXP += " AND D_E_L_E_T_=''"+ CRLF
        cQryEXP += " ORDER BY FT_ENTRADA, FT_FILIAL "+ CRLF

        cQryEXP := ChangeQuery(cQryEXP)
        Conout(cQryEXP)
        MpSysOpenQuery(cQryEXP,"TMPEXP")

    While TMPEXP-> (!Eof())
        
        DbSelectArea("SFT")
        SFT-> (DBSETORDER(1))
        SFT-> (DBGOTO( TMPEXP->RECFT))
        
        //Atualiza a SFT
        SFT-> ( RecLock("SFT", .F.))

        SFT->FT_BASEPIS := 0.00
        SFT->FT_BASECOF := 0.00
            
        SFT->FT_ALIQPIS := 0.00
        SFT->FT_ALIQCOF := 0.00

        SFT->FT_CSTPIS := "07"
        SFT->FT_CSTCOF := "07"

        SFT->FT_TNATREC := "4314"
        SFT->FT_CNATREC := "999"

        SFT->FT_VALPIS := 0.00
        SFT->FT_VALCOF := 0.00


        SFT->(MSUnlock())

        TMPEXP->(DBSKIP())
        
    Enddo

    TMPEXP-> ( dbCloseArea())
*/

//----------------------------------Atualiza o SFT por NCM/CFOP(Tributadas)-------------------------------------//

    If Select("TMPNCM") > 0
        dbSelectArea("TMPNCM")
        dbCloseArea()
    EndIf


        cQryNCM := "SELECT SFT.R_E_C_N_O_ RECFT, FT_ENTRADA, FT_FILIAL, FT_NFISCAL, FT_SERIE, FT_ITEM,  FT_TOTAL, FT_CFOP, FT_POSIPI, FT_VALCONT, FT_BASEPIS, FT_BASECOF, FT_ALIQPIS, FT_ALIQCOF, FT_VALPIS, FT_VALCOF, FT_CSTPIS,  FT_CSTCOF, FT_ESPECIE "+ CRLF 
        cQryNCM += " FROM "+RetSqlName("SFT")+" SFT "+ CRLF
        cQryNCM += " WHERE FT_CFOP IN('5101','5102','5949','5124','5401','5403','5405','5116','6101','6102','6401','6403','6405','6108','6109','6116','5152','5151','5408','5409')"+ CRLF
        cQryNCM += " AND FT_ENTRADA >= '"+DTOS(aRet[1])+"' "+ CRLF
        cQryNCM += " AND FT_ENTRADA <= '"+DTOS(aRet[2])+"' "+ CRLF
        cQryNCM += " AND FT_POSIPI IN('02101200','04031000','04051000','04061090','04063000','04090000','07069000','07109000'"
        cQryNCM += ",'08135000','09021000','09030090','2101200','4031000','4051000'"
        cQryNCM += ",'4061090','4063000','4090000','7069000','7109000','8135000','9021000','9030090','16010000','16023230','17049020'"
        cQryNCM += ",'17049090','18062000','18063110','18063120','18063220','18069000','19012000','19052010','19052090','19053200'"
        cQryNCM += ",'19054000','19059020','19059090','20099000','20071000','20079910','20089100','20091200','20091900','20097100','20098990'"
        cQryNCM += ",'21032010','21033021','21041019','21041021','21050010','21050090','21069029','21069090','22029000','22041090'"+ CRLF
        cQryNCM += ",'22042100','22089000','34060000','39204310','39241000','42021900','48194000','48195000','48211000','73269090')"+ CRLF
        cQryNCM += " AND FT_TIPOMOV = 'S'"+ CRLF
        cQryNCM += " AND D_E_L_E_T_=''"+ CRLF
        cQryNCM += " ORDER BY FT_ENTRADA, FT_FILIAL "+ CRLF

        cQryNCM := ChangeQuery(cQryNCM)
        Conout(cQryNCM)
        MpSysOpenQuery(cQryNCM,"TMPNCM")

    While TMPNCM-> (!Eof())
        
        DbSelectArea("SFT")
        SFT-> (DBSETORDER(1))
        SFT-> (DBGOTO( TMPNCM->RECFT))
        
        //Atualiza a SFT
        SFT-> ( RecLock("SFT", .F.))

        SFT->FT_BASEPIS := TMPNCM->FT_VALCONT
        SFT->FT_BASECOF := TMPNCM->FT_VALCONT
            
        SFT->FT_ALIQPIS := 1.65 
        SFT->FT_ALIQCOF := 7.60 

        SFT->FT_CSTPIS := "01"
        SFT->FT_CSTCOF := "01"

        SFT->FT_VALPIS := ROUND(TMPNCM->FT_VALCONT *(1.65/100),2)
        SFT->FT_VALCOF := ROUND(TMPNCM->FT_VALCONT *(7.60/100),2)


        SFT->(MSUnlock())

        TMPNCM->(DBSKIP())
        
    Enddo

    TMPNCM-> ( dbCloseArea())

Endif


If aRet[3] == "Entradas"


//--------------------------------------Atualiza o SFT - Entradas-------------------------------------------//

    If Select("TMPENT") > 0
        dbSelectArea("TMPENT")
        dbCloseArea()
    EndIf

    cQryEnt := " SELECT SFT.R_E_C_N_O_ RECFT, FT_FILIAL, FT_NFISCAL, FT_SERIE, FT_ESPECIE, FT_CSTPIS, FT_CSTCOF, FT_VALCONT, FT_TOTAL, FT_BASEICM, FT_VALICM, FT_CFOP, FT_BASEPIS, FT_ALIQPIS, FT_ALIQCOF, FT_VALPIS, FT_VALCOF, FT_ITEM, FT_PRODUTO "
    cQryEnt += " FROM "+RetSqlName("SFT")+" SFT "+ CRLF
    cQryEnt += " WHERE FT_ENTRADA >= '"+DTOS(aRet[1])+"' "+ CRLF
    cQryEnt += "AND FT_ENTRADA <= '"+DTOS(aRet[2])+"' "+ CRLF
CQryEnt+=" AND FT_NFISCAL IN('000712482'"
CQryEnt+=",'000778707'"
CQryEnt+=",'000781089'"
CQryEnt+=",'000792219'"
CQryEnt+=",'000912918'"
CQryEnt+=",'000913699'"
CQryEnt+=",'000913700'"
CQryEnt+=",'000915024'"
CQryEnt+=",'000067192'"
CQryEnt+=",'000066006'"
CQryEnt+=",'000067654'"
CQryEnt+=",'000065380'"
CQryEnt+=",'000057905'"
CQryEnt+=",'000062665'"
CQryEnt+=",'000063078'"
CQryEnt+=",'000064196'"
CQryEnt+=",'000065325'"
CQryEnt+=",'000065637'"
CQryEnt+=",'000067130'"
CQryEnt+=",'000067517'"
CQryEnt+=",'000068773'"
CQryEnt+=",'000069019'"
CQryEnt+=",'000057589'"
CQryEnt+=",'000063709'"
CQryEnt+=",'000064445'"
CQryEnt+=",'000067282'"
CQryEnt+=",'000069588'"
CQryEnt+=",'000063187'"
CQryEnt+=",'000063445'"
CQryEnt+=",'000064974'"
CQryEnt+=",'000066455'"
CQryEnt+=",'000067375'"
CQryEnt+=",'000067955'"
CQryEnt+=",'000840092'"
CQryEnt+=",'000000038'"
CQryEnt+=",'000720087'"
CQryEnt+=",'000799636'"
CQryEnt+=",'000803646'"
CQryEnt+=",'002775967'"
CQryEnt+=",'000070326'"
CQryEnt+=",'000071301'"
CQryEnt+=",'000073322'"
CQryEnt+=",'000074271'"
CQryEnt+=",'000070471'"
CQryEnt+=",'000071299'"
CQryEnt+=",'000071595'"
CQryEnt+=",'000072917'"
CQryEnt+=",'000073415'"
CQryEnt+=",'000074540'"
CQryEnt+=",'000074896'"
CQryEnt+=",'000075290'"
CQryEnt+=",'000070543'"
CQryEnt+=",'000072052'"
CQryEnt+=",'000073720'"
CQryEnt+=",'000069142'"
CQryEnt+=",'000070583'"
CQryEnt+=",'000071139'"
CQryEnt+=",'000071672'"
CQryEnt+=",'000071916'"
CQryEnt+=",'000073185'"
CQryEnt+=",'000074743')"
CQryEnt+=" AND FT_PRODUTO IN('10112'"
CQryEnt+=",'13235'"
CQryEnt+=",'13062'"
CQryEnt+=",'10117'"
CQryEnt+=",'10362'"
CQryEnt+=",'10272')"
cQryEnt+= "AND FT_TIPOMOV = 'E'"
    //cQryEnt += "AND FT_CSTPIS = "70"
    cQryEnt += "AND D_E_L_E_T_=''"

        cQryEnt := ChangeQuery(cQryEnt)
        Conout(cQryEnt)
        MpSysOpenQuery(cQryEnt,"TMPENT")


    While TMPENT-> (!Eof())
        
        DbSelectArea("SFT")
        SFT-> (DBSETORDER(1))
        SFT-> (DBGOTO( TMPENT->RECFT))
        
        //Atualiza a SFT
        SFT-> ( RecLock("SFT", .F.))

        SFT->FT_BASEPIS := (TMPENT->FT_VALCONT)
        SFT->FT_BASECOF := (TMPENT->FT_VALCONT)
            
        SFT->FT_ALIQPIS := 0.99
        SFT->FT_ALIQCOF := 4.56

        SFT->FT_VALPIS := ROUND((TMPENT->FT_VALCONT * 0.99/100),2)
        SFT->FT_VALCOF := ROUND((TMPENT->FT_VALCONT * 4.56/100),2)

        SFT->FT_CSTPIS := "50"
        SFT->FT_CSTCOF := "50"


        SFT->(MSUnlock())

        TMPENT->(DBSKIP())
        
    Enddo

    TMPENT-> ( dbCloseArea())



    If Select("TMPDEL") > 0
        dbSelectArea("TMPDEL")
        dbCloseArea()
    EndIf

    cQryEnt := " SELECT SFT.R_E_C_N_O_ RECFT, FT_FILIAL, FT_NFISCAL, FT_SERIE, FT_ESPECIE, FT_CSTPIS, FT_CSTCOF, FT_VALCONT, FT_TOTAL, FT_BASEICM, FT_VALICM, FT_CFOP, FT_BASEPIS, FT_ALIQPIS, FT_ALIQCOF, FT_VALPIS, FT_VALCOF, FT_ITEM, FT_PRODUTO "
    cQryEnt += " FROM "+RetSqlName("SFT")+" SFT "+ CRLF
    cQryEnt += " WHERE FT_ENTRADA >= '"+DTOS(aRet[1])+"' "+ CRLF
    cQryEnt += "AND FT_ENTRADA <= '"+DTOS(aRet[2])+"' "+ CRLF
CQryEnt+=" AND FT_PRODUTO IN('100801'"
CQryEnt+=",'100161'"
CQryEnt+=",'10161'"
CQryEnt+=",'63093'"
CQryEnt+=",'63176'"
CQryEnt+=",'63113'"
CQryEnt+=",'63189'"
CQryEnt+=",'40130'"
CQryEnt+=",'40131'"
CQryEnt+=",'63135')"
cQryEnt += " AND FT_TIPOMOV = 'E'"
cQryEnt += " AND FT_CSTPIS = '70'"
//cQryEnt += " AND FT_BASEPIS = 0.00"
cQryEnt += " AND D_E_L_E_T_=''"

        cQryEnt := ChangeQuery(cQryEnt)
        Conout(cQryEnt)
        MpSysOpenQuery(cQryEnt,"TMPDEL")


    While TMPDEL-> (!Eof())
        
        DbSelectArea("SFT")
        SFT-> (DBSETORDER(1))
        SFT-> (DBGOTO( TMPDEL->RECFT))
        
        //Atualiza a SFT
        SFT-> ( RecLock("SFT", .F.))

		//Atualiza o SFT - Deleta os movimentos com base no RECNO.

		SFT->(DBDelete())

        SFT->(MSUnlock())

        TMPDEL->(DBSKIP())
        
    Enddo

    TMPDEL-> ( dbCloseArea())
 

    If Select("TMPFRT") > 0
        dbSelectArea("TMPFRT")
        dbCloseArea()
    EndIf

    cQryEnt := " SELECT SFT.R_E_C_N_O_ RECFT, FT_FILIAL, FT_NFISCAL, FT_SERIE, FT_ESPECIE, FT_CSTPIS, FT_CSTCOF, FT_VALCONT, FT_TOTAL, FT_BASEICM, FT_VALICM, FT_CFOP, FT_BASEPIS, FT_ALIQPIS, FT_ALIQCOF, FT_VALPIS, FT_VALCOF, FT_ITEM, FT_PRODUTO, FT_INDNTFR, FT_CODBCC "
    cQryEnt += " FROM "+RetSqlName("SFT")+" SFT "+ CRLF
    cQryEnt += " WHERE FT_ENTRADA >= '"+DTOS(aRet[1])+"' "+ CRLF
    cQryEnt += "AND FT_ENTRADA <= '"+DTOS(aRet[2])+"' "+ CRLF
    cQryEnt += " AND FT_ESPECIE = 'CTE'"
    cQryEnt += " AND FT_TIPOMOV = 'E'"
    cQryEnt += " AND FT_CSTPIS = '50'"
    //cQryEnt += " AND FT_BASEPIS = 0.00"
    cQryEnt += " AND D_E_L_E_T_=''"

        cQryEnt := ChangeQuery(cQryEnt)
        Conout(cQryEnt)
        MpSysOpenQuery(cQryEnt,"TMPFRT")


    While TMPFRT-> (!Eof())
        
        DbSelectArea("SFT")
        SFT-> (DBSETORDER(1))
        SFT-> (DBGOTO( TMPFRT->RECFT))
        
        //Atualiza a SFT
        SFT-> ( RecLock("SFT", .F.))


		SFT->FT_INDNTFR := "0"
        SFT->FT_CODBCC  := "07"

        SFT->(MSUnlock())

        TMPFRT->(DBSKIP())
        
    Enddo

    TMPFRT-> ( dbCloseArea())

Endif

Return
