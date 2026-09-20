#INCLUDE "rwmake.ch"
#include "protheus.ch"
#INCLUDE "TBICONN.CH"
#include "topconn.ch"
#Include 'FILEIO.CH'

/*--------------------------------------------------------------------*
| Func:  ExtT154Fat()                                                 |
| Autor: Edmar Paranhos                                               |
| Data:  28/09/2023                                                   |
| Desc:  Gera arquivo TXT no layout TAF dos titulos com Retenção.     |
| Obs.:  Ajuste para atender aos Eventos REINF.                       |
*---------------------------------------------------------------------*/

User Function ExtT154Fat()

	Local Nx
	Local nY
	Local lErroPrc := .F.
	Local dDtini := date()
	Local dDtfim := date()
	Local cQuery := ""
	Private oDlg, oDlg1
	Private lOk
	Private lContinua := .T.
	Private nNumNf := 0
	Private cSerie := 0
	Private dDataE
	Private cDir   := "C:\Temp\"
	Private cNomeArq := Space(25)
	Private cFcorr := cFilAnt 
	Private cEmpc  := cEmpAnt 
	Private cUfFil  := Posicione("SM0",1,cEmpAnt+cFilAnt,"M0_ESTENT")
	Private cIeFil  := Posicione("SM0",1,cEmpAnt+cFilAnt,"M0_INSC")
	Private nValctb := 0
	Private cNature := ""
	Private cCliFor := ""
	Private cLojaCF := ""
	Private cCF2    := ""
	Private nBasIR := 0
	Private nBasCsrf := 0
	Private nValIrf := 0
	Private nValPis := 0
	Private nValCof := 0
	Private nValCsl := 0
	Private nBasIR := 0
	Private cNatRen:= ""
	Private cBxE2  := ""

	//Private cUf		:= "" 
	//Private cCprb	:= "0" //0 = Não|1 = Sim

	MsgInfo("Esta rotina irá gerar o arquivo .TXT Layout TAF apenas para a filial Logada!","Informação!")

	DEFINE MSDIALOG oDlg1 FROM 096,042 TO 343,520 TITLE OemToAnsi("Arquivo Texto Layout TAF") PIXEL
	DEFINE FONT oBold NAME "Arial" SIZE 0, -12 BOLD


	@ 007,025 SAY "Data Inicial"  of oDlg1 PIXEL
	@ 016,025 Get dDtini Size 50,09   of oDlg1 PIXEL

	@ 030,025 SAY "Data Final"  of oDlg1 PIXEL
	@ 038,025 MsGet dDtfim Size 50,09 Of oDlg Pixel

	@ 053,025 SAY "Drive Destino:"  of oDlg1 PIXEL
	@ 060,025 MsGet cDir PICTURE "@!" Size 45,09 Of oDlg Pixel //PICTURE "@!"

	@ 073,025 SAY "Nome do Arquivo:"  of oDlg1 PIXEL
	@ 082,025 MsGet cNomeArq PICTURE "@!" Size 69,09 Of oDlg Pixel //PICTURE "@!"

	@ 010,93 SAY "Gera Notas de Serviços Tomados/Prestados com" of oDlg1 PIXEL
	@ 017,93 SAY "Retenção referente ao periodo selecionado." of oDlg1 PIXEL

	@ 025,93 SAY "Cria arquivo .TXT para importação no SIGATAF." of oDlg1 PIXEL

	@ 031,88 BITMAP oBitmap1 SIZE 126, 064 OF oDlg NOBORDER FILENAME "\system\reinf.bmp" PIXEL

	@ 100,55  BUTTON "Processar"  SIZE 55 ,15   	FONT oDlg1:oFont  OF oDlg1 PIXEL ACTION (lContinua := .T.,ODlg1:End())
	@ 100,130 BUTTON "Cancelar"   SIZE 55 ,15       FONT oDlg1:oFont  OF oDlg1 PIXEL ACTION (lContinua := .F.,ODlg1:End())
	ACTIVATE MSDIALOG oDlg1 CENTERED


	If lContinua .And. (Empty(dDtini) .Or. Empty(dDtfim))
		HELP(2,"ARQT154","Datas Invalidas, favor preencha novamente!")

	ElseIf lContinua


		FWMsgRun(, {|| lErroPrc := GeraT154F( dDtini,dDtfim) }, "Processando Arquivo.", "Gerando Layout TAF, Aguarde!")

		If !lErroPrc
			MsgInfo('Arquivo .TXT gerado com sucesso!')
		Else
			Alert('Erro para atualizar.')
		Endif

	Endif

Return


/*--------------------------------------------------------------------*
| Func:  GeraT154F ()                                                 |
| Autor: Edmar Paranhos                                               |
| Data:  28/09/2023                                                   |
| Desc:  Realiza o Select e alimenta os Arrays para cada Layouts.     |
| Obs.:  Busca Valor e Base INSS da SD1/SF1/SE2.                      |
*---------------------------------------------------------------------*/

Static Function GeraT154F  (dDtini,dDtfim)

	Local aReg003:= {} 
	Local aReg154:= {} 
	Local aR154AG:= {}
	Local aR154AH:= {}
	Local aR154H1:= {}
	Local aR154H2:= {}
	Local aR154H3:= {}
	Local aR154AB:= {}
	Local aReg158:= {} 
	Local aR158AA:= {}
	Local aR158B1:= {}
	Local aR158B2:= {}
	Local aR158B3:= {}
	Local aR158B4:= {}
	Local cLin 

    cQuery := " SELECT F1.F1_FILIAL, F1.F1_TIPO, F1.F1_DOC, F1.F1_SERIE, F1.F1_FORNECE, F1.F1_LOJA, SUM(D1.D1_TOTAL) AS D1TOT, SUM(D1.D1_BASEIRR) AS BSIRF,SUM(D1.D1_BASEPIS) AS D1BSPI, SUM(D1.D1_BASECOF) AS D1BSCF, SUM(D1.D1_BASECSL) AS D1BSCS, SUM(D1.D1_VALIRR) AS VLIRF,SUM(D1.D1_VALPIS) AS D1VLPS, SUM(D1.D1_VALCOF) AS D1VLCF, SUM(D1.D1_VALCSL) AS D1VLCS, F2Q.F2Q_NATREN, E2.E2_BAIXA, F1.F1_EMISSAO,F1.F1_DTDIGIT FROM " + RetSqlName("SF1") + " F1"

    cQuery += " INNER JOIN " + RetSqlName("SD1") + " D1"
    cQuery += "       ON F1.F1_DOC = D1.D1_DOC"
    cQuery += "       AND F1.F1_SERIE = D1.D1_SERIE"
    cQuery += "       AND F1.F1_FORNECE = D1.D1_FORNECE"
    cQuery += "       AND F1.F1_LOJA = D1.D1_LOJA"
	cQuery += "       AND F1.D_E_L_E_T_ = ' '"
    cQuery += "       AND (D1.D1_BASEIRR > 0 OR D1.D1_BASEPIS > 0 OR D1.D1_BASECOF > 0 OR D1.D1_BASECSL > 0)"
    cQuery += "       AND D1.D_E_L_E_T_ = ' '"
    cQuery += "       AND D1.D1_FILIAL = '" + xFilial ("SD1") + "'"

    cQuery += " INNER JOIN " + RetSqlName("F2Q") + " F2Q"
    cQuery += "       ON F2Q.F2Q_PRODUT = D1.D1_COD"
    cQuery += "       AND F2Q.D_E_L_E_T_ = ' '"
    cQuery += "       AND F2Q.F2Q_FILIAL = '" + fwxFilial("F2Q") + "'"

    cQuery += " INNER JOIN " + RetSqlName("SE2") + " E2"
    cQuery += "       ON E2.E2_NUM = F1.F1_DOC"
    cQuery += "       AND E2.E2_FORNECE = F1.F1_FORNECE"
    cQuery += "       AND E2.E2_LOJA = F1.F1_LOJA"
    //cQuery += "       AND E2.E2_SALDO > 0"
    cQuery += "       AND E2.E2_ORIGEM IN ('MATA100','MATA103')"
    cQuery += "       AND E2.D_E_L_E_T_ = ' '"
	cQuery += "       AND E2.E2_FILORIG = '" + cFilAnt + "'"
    //cQuery += "       AND E2.E2_FILORIG = '" + xFilial ("SE2") + "'"

    cQuery += " WHERE F1.F1_STATUS = 'A'"
    cQuery += " AND F1.F1_FILIAL = '" + xFilial ("SF1") + "'"
    cQuery += "   AND F1.F1_EMISSAO >= '"+DTOS(dDtini)+"' " + CRLF 
	cQuery += "   AND F1.F1_EMISSAO <=  '"+DTOS(dDtfim)+"' " + CRLF 
    cQuery += " GROUP BY F1.F1_EMISSAO,F1.F1_DTDIGIT, F1.F1_FILIAL,F1.F1_TIPO,F1.F1_DOC,F1.F1_SERIE,F1.F1_FORNECE,F1.F1_LOJA,F2Q.F2Q_NATREN, E2.E2_BAIXA"
    cQuery += " ORDER BY F1.F1_EMISSAO,F1.F1_DTDIGIT ASC, F1.F1_DOC, F1.F1_SERIE, F1.F1_FORNECE, F1.F1_LOJA"

	cQuery := ChangeQuery(cQuery)

	MpSysOpenQuery(cQuery,"TMP154")

	dbSelectArea("TMP154")

	TMP154->(dbGoTop())

	While TMP154-> ( !Eof())


		nNumNF := cValToChar( TMP154-> F1_DOC)

		cSerie := Alltrim( TMP154-> F1_SERIE)

		cCliFor := TMP154-> F1_FORNECE
		
		cCF2 := "F"+cCliFor	

		cLojaCF := TMP154-> F1_LOJA

		dDataE := TMP154-> F1_EMISSAO	

		cNature := "0"
	  
		nValctb:= cValToChar( TMP154-> D1TOT)

		nBasIR:= cValToChar( TMP154-> BSIRF)

		nBasCsrf:= cValToChar( TMP154-> D1BSPI)

		nValIrf:= cValToChar( TMP154-> VLIRF)

		nValPis:= cValToChar( TMP154-> D1VLPS)

		nValCof:= cValToChar( TMP154-> D1VLCF)

		nValCsl:= cValToChar( TMP154-> D1VLCS)

		cNatRen:= Alltrim( TMP154-> F2Q_NATREN)

		cBxE2 := TMP154-> E2_BAIXA

		TMP154-> ( DBSKIP())

		//Aadd( aReg003, "|T003|"+cCF2+cLojaCF+"|"+cRazaoS+"|01058|"+cCgcCpf+"|||"+cCodMun+"||03|"+cLograd+"|||||"+cUf+"|||||||20180101|2|||||||||||||||||"+cCprb+"|||2||")
		Aadd( aReg154, "|T154|"+ Alltrim(nNumNF) +"|"+cSerie+"|"+cCF2+cLojaCF+"|"+ dDataE+"|"+cNature+"||||||"+ Strtran(nValctb,".",",") +"|||||||||0|0|0|0|0|0|0|0|0|0||||0||||3||||||||||0|0|0||||")
		Aadd( aR154AG, "|T154AG|"+ cNatRen + "|2|"+ Strtran(nValctb,".",",")+"||||||")
		Aadd( aR154AH, "|T154AH|12|"+ Strtran(nBasIR,".",",") +"|"+ Strtran(nValIrf,".",",")+"|0|")    //IRRF
		Aadd( aR154AB, "|T154AB|1|" + Strtran(nValctb,".",",") + "|")

		Aadd( aReg158, "|T158|"+ Alltrim(nNumNF) +"|"+cSerie+"|"+cCF2+cLojaCF+"|"+ dDataE+"|"+cNature+"||"+ dDataE+"|01||"+Alltrim(cBxE2)+"|")
		Aadd( aR158AA, "|T158AA|"+ cNatRen + "|"+ Strtran(nValctb,".",",")+"|2||||||")
		Aadd( aR158B4, "|T158AB|28|"+ Strtran(nBasIR,".",",") +"|"+ Strtran(nValIrf,".",",")+"|0|")
		Aadd( aR158B1, "|T158AB|11|"+ Strtran(nBasCsrf,".",",") +"|"+ Strtran(nValCof,".",",")+"|0|")    
		Aadd( aR158B2, "|T158AB|18|"+ Strtran(nBasCsrf,".",",") + "|"+ Strtran(nValCsl,".",",")+"|0|")
		Aadd( aR158B3, "|T158AB|10|"+ Strtran(nBasCsrf,".",",") + "|"+ Strtran(nValPis,".",",")+"|0|")

		nArquivo := fcreate(cDir + cNomeArq, FC_NORMAL)

		if ferror() # 0
			msgalert ("ERRO AO CRIAR O ARQUIVO, ERRO: " + str(ferror()))
			lFalha := .T.

			else

			cLin := "|T001"+"|"
			cLin += cEmpc + cFcorr + "|"+"#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|#NAOGRAVAR#|" + CRLF
			cLin += "|T001AA"+"|"+cUfFil+"|"+ Alltrim(cIeFil) +"||"+ CRLF
			cLin += "|T001AN|00000000000000|EMPRESA EXEMPLO S.A|NOME DO RESPONSAVEL|0000000000|exemplo@empresa.com.br|"+ CRLF

			If fWrite(nArquivo,cLin,Len(cLin)) != Len(cLin)

			Endif  

				for nLinha := 1 to len(aReg154)
					For nLinha := 1 to len(aR154AG)
						For nLinha := 1 to len(aR154AH)
							For nLinha := 1 to len(aR154AB)	
								For nLinha := 1 to len(aReg158)
									For nLinha := 1 to len(aR158AA)
										For nLinha := 1 to len(aR158B4)	
											For nLinha := 1 to len(aR158B1)
												For nLinha := 1 to len(aR158B2)
													For nLinha := 1 to len(aR158B3)														fwrite(nArquivo, aReg154[ nLinha] + chr(13) + chr(10))			
													fwrite(nArquivo, aR154AG[ nLinha] + chr(13) + chr(10))
													fwrite(nArquivo, aR154AH[ nLinha] + chr(13) + chr(10))	
													fwrite(nArquivo, aR154AB[ nLinha] + chr(13) + chr(10))	
													fwrite(nArquivo, aReg158[ nLinha] + chr(13) + chr(10))			
													fwrite(nArquivo, aR158AA[ nLinha] + chr(13) + chr(10))
													fwrite(nArquivo, aR158B4[ nLinha] + chr(13) + chr(10))
													fwrite(nArquivo, aR158B1[ nLinha] + chr(13) + chr(10))	
													fwrite(nArquivo, aR158B2[ nLinha] + chr(13) + chr(10))
													fwrite(nArquivo, aR158B3[ nLinha] + chr(13) + chr(10))	

													if ferror() # 0
														msgalert ("ERRO GRAVANDO ARQUIVO, ERRO: " + str(ferror()))
														lFalha := .T.
													Endif

												Next
											Next
										Next
										Next
									Next
								Next					
							Next
						Next
					Next
				Next

		Endif

		fclose ( nArquivo)

	Enddo

	TMP154-> ( dbCloseArea())

Return
