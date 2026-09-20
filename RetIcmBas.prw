#include "rwmake.ch"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "FWBROWSE.CH"
#include "Protheus.ch"
#INCLUDE "TBICONN.CH"
#include "topconn.ch"
#INCLUDE "REPORT.CH"

/*---------------------------------------------------------------------*
| Func:  RetIcmBas()                                                   |
| Autor: Edmar Paranhos                                                |
| Data:  27/10/2022                                                    |
| Desc:  Retira o ICMS da Base de Cálculo do PIS/COFINS.               |
| Obs.:  /                                                             |
*---------------------------------------------------------------------*/

User Function RetIcmBas()

	Local aPergs   := {}
	Local lErroPrc := .F.
	Local nOpc2 := 0
	Private aRet   := {}

	aAdd( aPergs,{1,"Periodo de Apuração De."  ,Ctod(Space(8)),"","","","",50,.T.}) 
	aAdd( aPergs,{1,"Periodo de Apuração Até." ,Ctod(Space(8)),"","","","",50,.T.}) 


	If ParamBox(aPergs ,"Dedução do ICMS na Base PIS/COFINS.",aRet)

		FWMsgRun(, {||lErroPrc := AtuPiCFS() }, "Retirando o ICMS da Base do PIS/COFINS.", "Aguarde...")

		If !lErroPrc
	    	nOpc2 := Aviso("Base PIS/COFINS.","Bases de Cálculo atualizadas com Sucesso, Gerar Planilha?" ,{"Sim","Não"},1)

				If nOpc2 == 1
	   				U_ExecPlPC2()//Gera Planilha - Notas Processadas.
				Endif
		Endif
	Endif

	Return

/*---------------------------------------------------------------------*
| Func:  AtuPiCFS()                                                    |
| Autor: Edmar Paranhos                                                |
| Data:  27/10/2022                                                    |
| Desc:  Executa a Query/Update.                                       |
| Obs.:  /                                                             |
*---------------------------------------------------------------------*/

Static Function AtuPiCFS()

	Local cQuery
	Local nBasPCN := 0

	If Select("TMPICM") > 0
		dbSelectArea("TMPICM")
		dbCloseArea()
	EndIf

	cQuery := "SELECT SFT.R_E_C_N_O_ AS RECNOSFT,SF3.R_E_C_N_O_ AS RECNOSF3, FT_FILIAL,FT_ENTRADA,FT_NFISCAL,FT_CFOP,FT_SERIE,FT_ESPECIE,FT_PRODUTO,FT_ITEM,F3_FILIAL, F3_REPROC, FT_TOTAL, FT_VALCONT, FT_VALIPI, FT_BASEPIS, FT_BASECOF, FT_VALICM, FT_VALPIS, FT_VALCOF, FT_TES"+ CRLF
	cQuery += " FROM "+RetSqlName("SFT")+" SFT "+ CRLF
	cQuery += "  INNER JOIN " + RetSqlName("SF3") + " SF3 ON (F3_FILIAL = FT_FILIAL)" + CRLF 
	cQuery += "   AND F3_NFISCAL = FT_NFISCAL " + CRLF 
	cQuery += "   AND F3_SERIE = FT_SERIE " + CRLF 
	cQuery += "   AND F3_ESPECIE = FT_ESPECIE " + CRLF 
	cQuery += "   AND F3_CFO = FT_CFOP " + CRLF
	cQuery += "   AND F3_CLIEFOR = FT_CLIEFOR " + CRLF 
	cQuery += "   AND F3_LOJA = FT_LOJA " + CRLF
	cQuery += "   AND F3_TIPO = FT_TIPO" + CRLF 
	cQuery += "   AND F3_IDENTFT = FT_IDENTF3 " + CRLF  
	cQuery += "   WHERE SFT.D_E_L_E_T_= ''"+ CRLF 
	cQuery += "   AND SFT.FT_FILIAL = '" + xFilial ("SFT") + "' " + CRLF 
	cQuery += "   AND SFT.FT_ENTRADA >= '"+DTOS(aRet[1])+"' " + CRLF 
	cQuery += "   AND SFT.FT_ENTRADA <= '"+DTOS(aRet[2])+"' "+ CRLF 
	cQuery += "   AND SFT.FT_TIPOMOV = 'S'"+ CRLF 
	cQuery += "   AND SF3.F3_REPROC <> 'N'"+ CRLF 
	cQuery += "   AND SF3.F3_TIPO <> 'S'"+ CRLF 
	cQuery += "   AND SFT.FT_VALICM > 0 "+ CRLF
	cQuery += "   AND SFT.FT_VALPIS > 0 "+ CRLF
	//cQuery += "   AND SFT.FT_DTCANC = ' '"
	cQuery += "   AND SF3.D_E_L_E_T_= ''"+ CRLF 

	cQuery := ChangeQuery(cQuery)

	//TCQUERY cQuery NEW ALIAS "TMPICM"

	Conout(cQuery)
	MpSysOpenQuery(cQuery,"TMPICM")

	While TMPICM-> (!Eof())
		
	//Atualiza a SFT - RECNO
		DbSelectArea("SFT")
		SFT-> (DBSETORDER(2))
		SFT-> (DBGOTO( TMPICM-> RECNOSFT))

		SFT-> ( RecLock("SFT", .F.))

		nBasPCN:= TMPICM->FT_BASEPIS - TMPICM->FT_VALICM

		SFT->FT_BASEPIS := nBasPCN
		SFT->FT_VALPIS  := ROUND(SFT->FT_BASEPIS * 1.65/100,2)

		SFT->FT_BASECOF := nBasPCN
		SFT->FT_VALCOF  := ROUND(SFT->FT_BASECOF * 7.6/100,2)

		SFT->(MSUnlock())

		//Atualiza a SF3 - RECNO
		DbSelectArea("SF3")
		SF3-> (DBSETORDER(2))
		SF3-> (DBGOTO( TMPICM-> RECNOSF3))
		
		SF3-> ( RecLock("SF3", .F.))

		SF3->F3_REPROC := "N"

		SF3->(MSUnlock())

		TMPICM->(DBSKIP())
		
	Enddo

	TMPICM-> ( dbCloseArea())

	Return

/*---------------------------------------------------------------------*
| Func:  ExecPlPC2()                                                  |
| Autor: Edmar Paranhos                                                |
| Data:  28/10/2022                                                   |
| Desc:  Cria o arquivo planilha (Excel ou Open Office).              |
| Obs.:  Uso generico - estudo.                                       |
*---------------------------------------------------------------------*/

User Function ExecPlPC2()

    Local aArea   := GetArea()
    Local cQuery2 := ""
    Local oFWMsExcel
    //Local oExcel
    Local cArquivo:= GetTempPath()+'AlterSFT2.xml'

    //Consulta os dados
	
 	cQuery2 := "SELECT SFT.R_E_C_N_O_ AS RECNOSFT,SF3.R_E_C_N_O_ AS RECNOSF3, FT_FILIAL,FT_ENTRADA,FT_NFISCAL,FT_CFOP,FT_SERIE,FT_ESPECIE,FT_PRODUTO,FT_ITEM,F3_FILIAL, F3_REPROC, FT_TOTAL, FT_VALCONT, FT_VALIPI, FT_BASEPIS, FT_BASECOF, FT_VALICM, FT_VALPIS, FT_VALCOF, FT_TES"+ CRLF
	cQuery2 += " FROM "+RetSqlName("SFT")+" SFT "+ CRLF
	cQuery2 += "  INNER JOIN " + RetSqlName("SF3") + " SF3 ON (F3_FILIAL = FT_FILIAL)" + CRLF 
	cQuery2 += "   AND F3_NFISCAL = FT_NFISCAL " + CRLF 
	cQuery2 += "   AND F3_SERIE = FT_SERIE " + CRLF 
	cQuery2 += "   AND F3_ESPECIE = FT_ESPECIE " + CRLF 
	cQuery2 += "   AND F3_CFO = FT_CFOP " + CRLF
	cQuery2 += "   AND F3_CLIEFOR = FT_CLIEFOR " + CRLF 
	cQuery2 += "   AND F3_LOJA = FT_LOJA " + CRLF
	cQuery2 += "   AND F3_TIPO = FT_TIPO" + CRLF 
	cQuery2 += "   AND F3_IDENTFT = FT_IDENTF3 " + CRLF  
	cQuery2 += "   WHERE SFT.D_E_L_E_T_= ''"+ CRLF 
	cQuery2 += "   AND SFT.FT_FILIAL = '" + xFilial ("SFT") + "' " + CRLF 
	cQuery2 += "   AND SFT.FT_ENTRADA >= '"+DTOS(aRet[1])+"' " + CRLF 
	cQuery2 += "   AND SFT.FT_ENTRADA <= '"+DTOS(aRet[2])+"' "+ CRLF 
	cQuery2 += "   AND SFT.FT_TIPOMOV = 'S'"+ CRLF 
	cQuery2 += "   AND SF3.F3_REPROC = 'N'"+ CRLF 
	cQuery2 += "   AND SF3.F3_TIPO <> 'S'"+ CRLF 
	cQuery2 += "   AND SFT.FT_VALICM > 0 "+ CRLF
	cQuery2 += "   AND SFT.FT_VALPIS > 0 "+ CRLF
	//cQuery += "   AND SFT.FT_DTCANC = ' '"
	cQuery2 += "   AND SF3.D_E_L_E_T_= ''"+ CRLF 

	cQuery2 := ChangeQuery(cQuery2)

	Conout(cQuery2)
	MpSysOpenQuery(cQuery2,"QRYICM")

    //TCQuery cQuery2 New Alias "QRYICM"
     
    //Criando o objeto que irá gerar o conteúdo do Excel
    oFWMsExcel := FWMSExcel():New()
     
    //Notas
    oFWMsExcel:AddworkSheet("Notas")
	//FT_FILIAL,FT_ENTRADA,FT_NFISCAL,FT_CFOP,FT_SERIE,FT_ESPECIE,FT_PRODUTO,FT_ITEM,F3_FILIAL, F3_REPROC, FT_TOTAL, FT_VALCONT, FT_VALIPI, FT_BASEPIS, FT_BASECOF, FT_VALICM, FT_VALPIS, FT_VALCOF"
        oFWMsExcel:AddTable("Notas","Notas")
        oFWMsExcel:AddColumn("Notas","Notas","Nota Fiscal",1,1)
        oFWMsExcel:AddColumn("Notas","Notas","Serie",1,1)
		oFWMsExcel:AddColumn("Notas","Notas","Especie",1,1)
		oFWMsExcel:AddColumn("Notas","Notas","CFOP",1,1)
        oFWMsExcel:AddColumn("Notas","Notas","Produto",1,1)
        oFWMsExcel:AddColumn("Notas","Notas","Item",1,1)
		oFWMsExcel:AddColumn("Notas","Notas","Vlr.Contabil",2,2)
        oFWMsExcel:AddColumn("Notas","Notas","Vlr.Total",2,2)
        oFWMsExcel:AddColumn("Notas","Notas","Vlr.IPI",2,2)
		oFWMsExcel:AddColumn("Notas","Notas","Vlr.ICMS",2,2)
		oFWMsExcel:AddColumn("Notas","Notas","Base PIS",2,2)
		oFWMsExcel:AddColumn("Notas","Notas","Base COFINS",2,2)
		oFWMsExcel:AddColumn("Notas","Notas","Vlr.PIS",2,2)
		oFWMsExcel:AddColumn("Notas","Notas","Vlr.COFINS",2,2)
		oFWMsExcel:AddColumn("Notas","Notas","TES",1,1)

        While !(QRYICM->(EoF()))
            oFWMsExcel:AddRow("Notas","Notas",{;
					QRYICM->FT_NFISCAL,;
                    QRYICM->FT_SERIE,;
					QRYICM->FT_ESPECIE,;
					QRYICM->FT_CFOP,;
                	QRYICM->FT_PRODUTO,;
					QRYICM->FT_ITEM,;
					QRYICM->FT_VALCONT,;
					QRYICM->FT_TOTAL,;
					QRYICM->FT_VALIPI,;
					QRYICM->FT_VALICM,;
					QRYICM->FT_BASEPIS,;
					QRYICM->FT_BASECOF,;
					QRYICM->FT_VALPIS,;
					QRYICM->FT_VALCOF,;
					QRYICM->FT_TES})
         
            QRYICM->(DbSkip())

        EndDo
     
    oFWMsExcel:Activate()
    oFWMsExcel:GetXMLFile(cArquivo)
         

	ShellExecute( "Open", cArquivo, "", "", 1 ) //Função inserida para maquinas que não possuem o Excel.

    //oExcel := MsExcel():New()           //Abre uma nova conexão com Excel
    //oExcel:WorkBooks:Open(cArquivo)     //Abre uma planilha
    //oExcel:SetVisible(.T.)              //Visualiza a planilha
    //oExcel:Destroy()                    //Encerra o processo do gerenciador de tarefas
     
    QRYICM->(DbCloseArea())
	
    RestArea(aArea)

Return
