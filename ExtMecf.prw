#INCLUDE "rwmake.ch"
#include "protheus.ch"
#INCLUDE "TBICONN.CH"
#include "topconn.ch"
#Include 'FILEIO.CH'

/*--------------------------------------------------------------------*
| Func:  ExtMecf()                                                    |
| Autor: Edmar Paranhos                                               |
| Data:  19/01/2023                                                   |
| Desc:  Gera arquivo Bloco M (LALUR/LACS).                           |
| Obs.:  \                                                            |
*---------------------------------------------------------------------*/

User Function ExtMecf()

	Local Nx
	Local nY
	Local lErroPrc := .F.
	Local dDtini := date()
	Local dDtfim := date()
	Local cQuery := ""
	Private aCmbECF:= {'1=LALUR','2=LACS'}
	Private cCmbECF:= ""
	Private aCmbAdc:= {'1=Adição','2=Exclusão'}
	Private cCmbAdc:= ""
	Private oDlg,oDlg1
	Private lOk
	Private lContinua := .T.
	Private cCodCta := ""
	Private cNumLot := ""
	Private cTipoAdc:= ""
	Private cTipoTx := ""
	//Private dDataE
	Private cDir   := "C:\Temp\"
	Private cNomeArq := Space(35)
	Private cFcorr := cFilAnt 
	Private cEmpc  := cEmpAnt 
	Private nValLct := 0

	DEFINE MSDIALOG oDlg1 FROM 096,042 TO 343,520 TITLE OemToAnsi("Bloco M - LALUR/LACS") PIXEL
	DEFINE FONT oBold NAME "Arial" SIZE 0, -12 BOLD


	@ 007,025 SAY "Data Inicial"  of oDlg1 PIXEL COLOR CLR_HBLUE
	@ 016,025 Get dDtini Size 50,09   of oDlg1 PIXEL

	@ 030,025 SAY "Data Final"  of oDlg1 PIXEL COLOR CLR_HBLUE
	@ 038,025 MsGet dDtfim Size 50,09 Of oDlg Pixel 

	@ 007,93 say "Lalur/LACS?" Pixel Of oDlg COLOR CLR_HBLUE
	@ 016,93 ComboBox cCmbECF ITEMS aCmbECF SIZE 45,10 Size 50,10 VALID(!EMPTY(cCmbECF)) when .T. pixel 

	@ 007,150 say "Tipo?" Pixel Of oDlg COLOR CLR_HBLUE
	@ 016,150 ComboBox cCmbAdc ITEMS aCmbAdc SIZE 45,10 Size 50,10 VALID(!EMPTY(cCmbAdc)) when .T. pixel 

	@ 053,025 SAY "Drive Destino:"  of oDlg1 PIXEL COLOR CLR_HBLUE
	@ 060,025 MsGet cDir PICTURE "@!" Size 45,09 Of oDlg Pixel //PICTURE "@!"

	//@ 073,025 SAY "Nome do Arquivo:"  of oDlg1 PIXEL COLOR CLR_HBLUE
	//@ 082,025 MsGet cNomeArq PICTURE "@!" Size 69,09 Of oDlg Pixel //PICTURE "@!"

	@ 020,88 BITMAP oBitmap1 SIZE 126, 064 OF oDlg NOBORDER FILENAME "\system\ecf.bmp" PIXEL

	@ 100,55  BUTTON "Processar"  SIZE 55 ,15   	FONT oDlg1:oFont  OF oDlg1 PIXEL ACTION (lContinua := .T.,ODlg1:End())
	@ 100,130 BUTTON "Cancelar"   SIZE 55 ,15       FONT oDlg1:oFont  OF oDlg1 PIXEL ACTION (lContinua := .F.,ODlg1:End())
	
	ACTIVATE MSDIALOG oDlg1 CENTERED


	If lContinua .And. (Empty(dDtini) .Or. Empty(dDtfim))
		HELP(2,"ARQTECF","Datas Invalidas, favor preencha novamente!")

	ElseIf lContinua


		FWMsgRun(, {|| lErroPrc := GeraECF9( dDtini,dDtfim) }, "Processando Arquivo.", "Gerando Bloco M, Aguarde!")

		If !lErroPrc
			MsgInfo('Arquivo .TXT gerado com sucesso!')
		Else
			Alert('Erro para atualizar.')
		Endif

	Endif

Return


/*--------------------------------------------------------------------*
| Func:  GeraECF9 ()                                                  |
| Autor: Edmar Paranhos                                               |
| Data:  23/06/2022                                                   |
| Desc:  Realiza o Select e alimenta os Arrays para cada Layouts.     |
| Obs.:                                                               |
*---------------------------------------------------------------------*/

Static Function GeraECF9  (dDtini,dDtfim)

	Local aReg305:= {} 
	Local aReg310:= {} 
	Local aReg312:= {}
	Local aReg355:= {} 
	Local aReg360:= {} 
	Local aReg362:= {}
	Local nTotal := 0
	Local cConta := ''
	Local nLinha := 1  
	Local nLin   := 1  
	Local cDataM := ''
	Local cDataA := ''

	If Select("TMPECF") > 0
		dbSelectArea("TMPECF")
		dbCloseArea()
	EndIf

	If cCmbAdc == '1'
	   cTipoAdc := 'D'
	Endif

	If cCmbAdc == '2'
	   cTipoAdc := 'C'
	Endif

	cQuery := 'SELECT CSB_CODREV,CSB_DTLANC,CSB_NUMLOT,CSB_CODCTA, SUM(CSB_VLPART) AS "VLRCS"'+ CRLF 
	cQuery += " FROM "+RetSqlName("CSB") +" CSB " + CRLF 
	cQuery += " WHERE CSB.CSB_INDDC = '"+cTipoAdc+"' " + CRLF 
	cQuery += " AND CSB.CSB_DTLANC >= '"+DTOS(dDtini)+"' " + CRLF
	cQuery += " AND CSB.CSB_DTLANC <= '"+DTOS(dDtfim)+"' " + CRLF 
	//FH - EMP 14
    cQuery += " AND CSB.CSB_CODREV = '000078' " + CRLF 
	cQuery += " AND CSB.CSB_CODCTA IN ('321101001','321101002','321201001','321201002','321201003','331101001','331201001','331201002','331201003','411301001','421303001','430109001','430109002','430109004','430109006','430110001','51130300','512401004','513501007','533101004')" + CRLF
	cQuery += " AND CSB.D_E_L_E_T_ = '' " + CRLF
    cQuery += " GROUP BY CSB_CODREV,CSB_DTLANC,CSB_NUMLOT,CSB_CODCTA" + CRLF
	cQuery += " ORDER BY CSB_CODCTA" + CRLF
	cQuery := ChangeQuery(cQuery)

	DbUseArea( .T. , "TOPCONN" , TCGenQry(,,cQuery) , 'TMPECF' , .F. , .T. )

	While TMPECF-> ( !Eof())

		If cConta <> Alltrim(TMPECF->CSB_CODCTA)
			
		cQuery := " SELECT CSB_CODCTA,SUM(CSB_VLPART) AS 'VLRCS' FROM "+RetSqlName("CSB") +" CSB " + CRLF
		cQuery += " WHERE CSB.CSB_INDDC = '"+cTipoAdc+"' " + CRLF 
		cQuery += " AND CSB.CSB_DTLANC >= '"+DTOS(dDtini)+"' " + CRLF
		cQuery += " AND CSB.CSB_DTLANC <= '"+DTOS(dDtfim)+"' " + CRLF 
		//FH
        cQuery += " AND CSB.CSB_CODREV = '000078' " + CRLF 
		cQuery += " AND CSB.CSB_CODCTA IN ('321101001','321101002','321201001','321201002','321201003','331101001','331201001','331201002','331201003','411301001','421303001','430109001','430109002','430109004','430109006','430110001','51130300','512401004','513501007','533101004')" + CRLF
		cQuery += " AND CSB_CODCTA = '"+TMPECF->CSB_CODCTA+"' "
		cQuery += " AND CSB.D_E_L_E_T_ = '' " + CRLF 
		cQuery += " GROUP BY CSB_CODCTA" + CRLF

		cQuery := ChangeQuery(cQuery)

		MPSysOpenQuery(cQuery,"TRBCTA")

		cConta := TMPECF->CSB_CODCTA
		nTotal := TRBCTA->VLRCS
		
		cCodCta := Alltrim( TRBCTA->CSB_CODCTA)
		nValLct := cValToChar( nTotal)
		
		TRBCTA->(DbCloseArea())
		
		//LALUR
		Aadd( aReg305, "|M305|"+cCodCta+"|"+StrTran(nValLct,".",",")+"|"+cTipoAdc+"|") 
		Aadd( aReg310, {"|M310|"+ cCodCta +"|"+"|"+StrTran(nValLct,".",",")+"|"+cTipoAdc+"|",cCodCta})
		//LACS
		Aadd( aReg355, "|M355|"+cCodCta+"|"+StrTran(nValLct,".",",")+"|"+cTipoAdc+"|")
		Aadd( aReg360, {"|M360|"+ cCodCta +"|"+"|"+StrTran(nValLct,".",",")+"|"+cTipoAdc+"|",cCodCta})
	
		Endif	

		TMPECF-> ( DBSKIP())
	Enddo

		DbSelectArea("TMPECF")
		TMPECF->(DBGOTOP())
		
		While TMPECF-> ( !Eof())
		
		cNumLot := Alltrim( TMPECF-> CSB_NUMLOT)	
		Aadd( aReg312, {"|M312|"+ cNumLot + "|",TMPECF->CSB_CODCTA})
		Aadd( aReg362, {"|M362|"+ cNumLot + "|",TMPECF->CSB_CODCTA})

	    TMPECF-> ( DBSKIP())
	Enddo

	//Cria o Nome Personalizado

	cDataM := Month2Str(dDtfim) //Mês
				
	cDataA := Year2Str(dDtfim) // Ano
	
	If cCmbECF == '1' .And. cCmbAdc == '1' //LALUR Adição
	nArquivo := fcreate(cDir + "ECF_GEN_LALUR_"+cDataM+cDataA+"_ADIC.txt", FC_NORMAL)
	ENDIF

	If cCmbECF == '1' .And. cCmbAdc == '2' //LALUR Exclusao
	nArquivo := fcreate(cDir + "ECF_GEN_LALUR_"+cDataM+cDataA+"_EXCL.txt", FC_NORMAL)
	ENDIF

	If cCmbECF == '2' .And. cCmbAdc == '1' //LACS Adição
	nArquivo := fcreate(cDir + "ECF_GEN_LACS_"+cDataM+cDataA+"_ADIC.txt", FC_NORMAL)
	ENDIF

	If cCmbECF == '2' .And. cCmbAdc == '2' //LACS Exclusao
	nArquivo := fcreate(cDir + "ECF_GEN_LACS_"+cDataM+cDataA+"_EXCL.txt", FC_NORMAL)
	ENDIF

	If cCmbECF == '1'//LALUR
		
		if ferror() # 0
			msgalert ("ERRO AO CRIAR O ARQUIVO, ERRO: " + str(ferror()))
			lFalha := .T.
		else

			for nLinha := 1 to len(aReg305) 
				fwrite(nArquivo, aReg305[ nLinha] + chr(13) + chr(10)) 
			Next
				
				for nLinha := 1 to len(aReg310)						
					fwrite(nArquivo, aReg310[ nLinha,1] + chr(13) + chr(10)) 
				
					For nLin := 1 to len(aReg312) 
				
					If Alltrim(aReg310[nLinha,2]) == Alltrim(aReg312[nLin,2])  
			
					fwrite(nArquivo, areg312[nLin,1] + chr(13) + chr(10)) 							
			
					Endif		
			
					Next
				Next
		Endif
	Endif

	If cCmbECF == '2'//LACS
		
		if ferror() # 0
			msgalert ("ERRO AO CRIAR O ARQUIVO, ERRO: " + str(ferror()))
			lFalha := .T.
		else

			for nLinha := 1 to len(aReg355) 
				fwrite(nArquivo, aReg355[ nLinha] + chr(13) + chr(10)) 
			Next
				
				for nLinha := 1 to len(aReg360)						
					fwrite(nArquivo, aReg360[ nLinha,1] + chr(13) + chr(10)) 
				
					For nLin := 1 to len(aReg362) 
				
					If Alltrim(aReg360[nLinha,2]) == Alltrim(aReg362[nLin,2])  
			
					fwrite(nArquivo, areg362[nLin,1] + chr(13) + chr(10)) 							
			
					Endif		
			
					Next
				Next
		Endif
	Endif

	fclose ( nArquivo)

	TMPECF-> ( dbCloseArea())

Return
