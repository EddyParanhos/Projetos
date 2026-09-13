#INCLUDE 'RWMAKE.CH'
#INCLUDE "Topconn.ch"
#INCLUDE "TBICONN.ch"
#INCLUDE "Protheus.ch"
#INCLUDE "REPORT.CH"

/*--------------------------------------------------------------------*
| Func:  ATFExecV2()                                                  |
| Autor: Edmar Paranhos                                               |
| Data:  28/07/2026                                                   |
| Desc:  Importação/Alteração de Ativos via ExecAuto                  |
|        Inclusão: ATFA012 com validação de duplicidade               |
|        Alteração: ATFA060 (Transferência) - CCusto/Conta/Chapinha   |
| Obs.:  Substitui Importação direta por ExecAuto com validações      |
 *---------------------------------------------------------------------*/

User Function ATFExecV2()

	Processa({|| U_AtExcV2P()}, "Processando Ativos...")

Return

/*--------------------------------------------------------------------*
| Func:  AtExcV2P()                                                 |
| Autor: Edmar Paranhos                                               |
| Data:  28/07/2026                                                   |
| Desc:  Processa importação/alteração via ExecAuto                   |
 *---------------------------------------------------------------------*/

User Function AtExcV2P()

	Local oDlg
	Local nOpct   := 2
	Local cLinha  := ""
	Local lPrim   := .T.
	Local aCampos := {}
	Local aDados  := {}
	Local cCampo
	Local cArqNome := ""
	Local cCmbOper := ""
	Local aCmbOper := {'1=Inclusão Novo (ATFA012)','2=Alteração Cadastral (ATFA060)'}
	Local nOpc1    := 0
	Local nAtual   := 50
	Local nTotReg  := 0
	Local nErros   := 0
	Local nSucess  := 0
	Local nSkip    := 0
	Local cLog     := ""
	Local cLogFile := ""
	Local cMsg     := ""
	Local aCab     := {}
	Local aItens   := {}
	Local aItem    := {}
	Local aParam   := {}
	Local i, j

	// Variáveis para Alteração
	Local cBase   := ""
	Local cItem   := ""
	Local cChapa  := ""
	Local cConta  := ""
	Local cCusto  := ""
	Local dDataTr := dDatabase

	Private cArqCSV := Space(40)
	Private aErro := {}
	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .T.

	Define MSDialog oDlg Title "Ativos SN1/SN3 - ExecAuto" From 0,0 To 195,570 Pixel STYLE DS_MODALFRAME

	@ 015,030 say "Operação:" Pixel Of oDlg COLOR CLR_HBLUE
	@ 014,080 ComboBox cCmbOper ITEMS aCmbOper SIZE 150,10 Valid(!EMPTY(cCmbOper)) When .T. Pixel

	@ 55,65 BUTTON "Imp.Arquivo" SIZE 55,15 FONT oDlg:oFont OF oDlg PIXEL ACTION (cArqNome:=cGetFile("Arquivo CSV|*.CSV","Seleção de Arquivo"),ODlg:End())
	@ 55,170 BUTTON "Cancelar"    SIZE 55,15 FONT oDlg:oFont OF oDlg PIXEL ACTION (nOpct:=2,ODlg:End())

	oDlg:lEscClose := .F.

	Activate MSDialog oDlg Centered

	If Empty(cCmbOper)
		MsgStop("Selecione uma operação!","[ATF_ExecAuto] - ATENCAO")
		Return
	EndIf

	If !File(cArqNome)
		MsgStop("O arquivo não foi selecionado!","[ATF_ExecAuto] - ATENCAO")
		Return
	EndIf

	// Lê o CSV e monta array aDados
	FT_FUSE(cArqNome)
	ProcRegua(FT_FLASTREC())
	FT_FGOTOP()
	While !FT_FEOF()

		cLinha := FT_FREADLN()

		If lPrim
			aCampos := Separa(cLinha,";",.T.)
			lPrim := .F.
		Else
			AADD(aDados,Separa(cLinha,";",.T.))
		EndIf

		IncProc("Lendo arquivo...")
		FT_FSKIP()

	EndDo
	FT_FUSE()

	nTotReg := Len(aDados)
	nErros := 0
	nSucess := 0
	nSkip := 0
	cLog := ""

	Do Case

		Case Left(cCmbOper,1) == "1" // INCLUSÃO NOVO
			Processa({|| V2Incluir(aCampos, aDados, @nSucess, @nErros, @nSkip, @cLog)}, "Incluindo Ativos...")

		Case Left(cCmbOper,1) == "2" // ALTERAÇÃO CADASTRAL
			Processa({|| V2Alterar(aCampos, aDados, @nSucess, @nErros, @cLog)}, "Alterando Ativos...")

	End Case

	// Gera log de processamento
	cLogFile := "\logs\ATF_ExecAuto_v2_" + DTOS(DATE()) + "_" + STRTRAN(TIME(),":","") + ".log"
	MemoWrite(cLogFile, cLog)

	// Resumo
	cMsg := "Processamento finalizado!" + CRLF + CRLF
	cMsg += "Total de registros: " + ALLTRIM(STR(nTotReg)) + CRLF
	cMsg += "Sucesso: " + ALLTRIM(STR(nSucess)) + CRLF
	If Left(cCmbOper,1) == "1"
		cMsg += "Ignorados (já existentes): " + ALLTRIM(STR(nSkip)) + CRLF
	EndIf
	cMsg += "Erros: " + ALLTRIM(STR(nErros)) + CRLF
	cMsg += CRLF + "Log salvo em: " + cLogFile

	ApMsgInfo(cMsg,"[ATF_ExecAuto] - SUCESSO.")

Return

/*--------------------------------------------------------------------*
| Func:  V2Incluir()                                                  |
| Desc:  Inclusão de Novos Ativos via ATFA012                         |
|        Valida duplicidade antes de incluir                          |
 *---------------------------------------------------------------------*/

Static Function V2Incluir(aCampos, aDados, nSucess, nErros, nSkip, cLog)

	Local i, j
	Local cCampo
	Local aCab := {}
	Local aItens := {}
	Local aItem := {}
	Local aParam := {}
	Local lExiste := .F.
	Local cFilSN1 := ""
	Local cBase   := ""
	Local cItem   := ""

	ProcRegua(Len(aDados))

	For i:=1 to Len(aDados)

		lMsErroAuto := .F.
		aCab := {}
		aItens := {}
		aItem := {}
		aParam := {}

		// Validação de duplicidade (N1_CBASE + N1_ITEM)
		lExiste := .F.
		cFilSN1 := xFilial("SN1")
		dbSelectArea("SN1")
		dbSetOrder(1) // N1_FILIAL + N1_CBASE + N1_ITEM

		// Procura campos no array
		cBase := ""
		cItem := ""
		For j:=1 to Len(aCampos)
			cCampo := AllTrim(aCampos[j])
			If cCampo == "N1_CBASE"
				cBase := aDados[i,j]
			ElseIf cCampo == "N1_ITEM"
				cItem := aDados[i,j]
			EndIf
		Next j

		If !Empty(cBase) .And. !Empty(cItem)
			lExiste := DbSeek(cFilSN1 + PADR(cBase,TamSX3("N1_CBASE")[1]) + PADR(cItem,TamSX3("N1_ITEM")[1]))
		EndIf

		If lExiste
			// Registro já existe - não inclui (validador de duplicidade)
			nSkip++
			cLog += "Linha " + ALLTRIM(STR(i)) + " - SKIP: "
			cLog += "Cod.Base: " + ALLTRIM(cBase) + " - "
			cLog += "Item: " + ALLTRIM(cItem) + " - "
			cLog += "Motivo: Já existe no cadastro" + CRLF
			IncProc("SKIP - Já existe: " + cBase + "-" + cItem)
			Loop
		EndIf

		If Empty(cBase) .Or. Empty(cItem)
			// Sem chave para identificar o ativo - não tenta incluir
			nErros++
			cLog += "Linha " + ALLTRIM(STR(i)) + " - ERRO: "
			cLog += "Campos N1_CBASE e N1_ITEM são obrigatórios" + CRLF
			Loop
		EndIf

		// Monta cabeçalho SN1
		For j:=1 to Len(aCampos)
			cCampo := AllTrim(aCampos[j])

			// Campos do cabeçalho SN1
			If cCampo == "N1_FILIAL"
				AADD(aCab, {"N1_FILIAL", aDados[i,j], NIL})
			ElseIf cCampo == "N1_CBASE"
				AADD(aCab, {"N1_CBASE", aDados[i,j], NIL})
			ElseIf cCampo == "N1_ITEM"
				AADD(aCab, {"N1_ITEM", aDados[i,j], NIL})
			ElseIf cCampo == "N1_AQUISIC"
				AADD(aCab, {"N1_AQUISIC", CTOD(aDados[i,j]), NIL})
			ElseIf cCampo == "N1_DESCRIC"
				AADD(aCab, {"N1_DESCRIC", aDados[i,j], NIL})
			ElseIf cCampo == "N1_QUANTD"
				AADD(aCab, {"N1_QUANTD", VAL(aDados[i,j]), NIL})
			ElseIf cCampo == "N1_CHAPA"
				AADD(aCab, {"N1_CHAPA", aDados[i,j], NIL})
			ElseIf cCampo == "N1_PATRIM"
				AADD(aCab, {"N1_PATRIM", aDados[i,j], NIL})
			ElseIf cCampo == "N1_GRUPO"
				AADD(aCab, {"N1_GRUPO", aDados[i,j], NIL})
			ElseIf cCampo == "N1_LOCAL"
				AADD(aCab, {"N1_LOCAL", aDados[i,j], NIL})
			ElseIf cCampo == "N1_NFISCAL"
				AADD(aCab, {"N1_NFISCAL", aDados[i,j], NIL})
			ElseIf cCampo == "N1_NSERIE"
				AADD(aCab, {"N1_NSERIE", aDados[i,j], NIL})
			ElseIf cCampo == "N1_TAXAPAD"
				AADD(aCab, {"N1_TAXAPAD", aDados[i,j], NIL})
			ElseIf cCampo == "N1_FORNEC"
				AADD(aCab, {"N1_FORNEC", aDados[i,j], NIL})
			ElseIf cCampo == "N1_LOJA"
				AADD(aCab, {"N1_LOJA", aDados[i,j], NIL})
			ElseIf cCampo == "N1_STATUS"
				AADD(aCab, {"N1_STATUS", aDados[i,j], NIL})
			EndIf
		Next j

		// Monta itens SN3
		aItem := {}
		For j:=1 to Len(aCampos)
			cCampo := AllTrim(aCampos[j])

			If cCampo == "N3_CBASE"
				AADD(aItem, {"N3_CBASE", aDados[i,j], NIL})
			ElseIf cCampo == "N3_ITEM"
				AADD(aItem, {"N3_ITEM", aDados[i,j], NIL})
			ElseIf cCampo == "N3_TIPO"
				AADD(aItem, {"N3_TIPO", aDados[i,j], NIL})
			ElseIf cCampo == "N3_BAIXA"
				AADD(aItem, {"N3_BAIXA", aDados[i,j], NIL})
			ElseIf cCampo == "N3_HISTOR"
				AADD(aItem, {"N3_HISTOR", aDados[i,j], NIL})
			ElseIf cCampo == "N3_CCONTAB"
				AADD(aItem, {"N3_CCONTAB", aDados[i,j], NIL})
			ElseIf cCampo == "N3_CUSTBEM"
				AADD(aItem, {"N3_CUSTBEM", aDados[i,j], NIL})
			ElseIf cCampo == "N3_CDEPREC"
				AADD(aItem, {"N3_CDEPREC", aDados[i,j], NIL})
			ElseIf cCampo == "N3_CDESP"
				AADD(aItem, {"N3_CDESP", aDados[i,j], NIL})
			ElseIf cCampo == "N3_CCORREC"
				AADD(aItem, {"N3_CCORREC", aDados[i,j], NIL})
			ElseIf cCampo == "N3_CCUSTO"
				AADD(aItem, {"N3_CCUSTO", aDados[i,j], NIL})
			ElseIf cCampo == "N3_CCCORR"
				AADD(aItem, {"N3_CCCORR", aDados[i,j], NIL})
			ElseIf cCampo == "N3_CCDESP"
				AADD(aItem, {"N3_CCDESP", aDados[i,j], NIL})
			ElseIf cCampo == "N3_CCCDEP"
				AADD(aItem, {"N3_CCCDEP", aDados[i,j], NIL})
			ElseIf cCampo == "N3_CCCDES"
				AADD(aItem, {"N3_CCCDES", aDados[i,j], NIL})
			ElseIf cCampo == "N3_DINDEPR"
				AADD(aItem, {"N3_DINDEPR", CTOD(aDados[i,j]), NIL})
			ElseIf cCampo == "N3_VORIG1"
				AADD(aItem, {"N3_VORIG1", VAL(aDados[i,j]), NIL})
			ElseIf cCampo == "N3_TXDEPR1"
				AADD(aItem, {"N3_TXDEPR1", VAL(aDados[i,j]), NIL})
			ElseIf cCampo == "N3_VORIG2"
				AADD(aItem, {"N3_VORIG2", VAL(aDados[i,j]), NIL})
			ElseIf cCampo == "N3_TXDEPR2"
				AADD(aItem, {"N3_TXDEPR2", VAL(aDados[i,j]), NIL})
			ElseIf cCampo == "N3_VORIG3"
				AADD(aItem, {"N3_VORIG3", VAL(aDados[i,j]), NIL})
			ElseIf cCampo == "N3_TXDEPR3"
				AADD(aItem, {"N3_TXDEPR3", VAL(aDados[i,j]), NIL})
			ElseIf cCampo == "N3_VORIG4"
				AADD(aItem, {"N3_VORIG4", VAL(aDados[i,j]), NIL})
			ElseIf cCampo == "N3_TXDEPR4"
				AADD(aItem, {"N3_TXDEPR4", VAL(aDados[i,j]), NIL})
			ElseIf cCampo == "N3_VORIG5"
				AADD(aItem, {"N3_VORIG5", VAL(aDados[i,j]), NIL})
			ElseIf cCampo == "N3_TXDEPR5"
				AADD(aItem, {"N3_TXDEPR5", VAL(aDados[i,j]), NIL})
			ElseIf cCampo == "N3_SUBCCON"
				AADD(aItem, {"N3_SUBCCON", aDados[i,j], NIL})
			ElseIf cCampo == "N3_CLVLCON"
				AADD(aItem, {"N3_CLVLCON", aDados[i,j], NIL})
			ElseIf cCampo == "N3_VRDACM1"
				AADD(aItem, {"N3_VRDACM1", VAL(aDados[i,j]), NIL})
			ElseIf cCampo == "N3_VRDACM2"
				AADD(aItem, {"N3_VRDACM2", VAL(aDados[i,j]), NIL})
			ElseIf cCampo == "N3_VRDACM3"
				AADD(aItem, {"N3_VRDACM3", VAL(aDados[i,j]), NIL})
			ElseIf cCampo == "N3_VRDACM4"
				AADD(aItem, {"N3_VRDACM4", VAL(aDados[i,j]), NIL})
			ElseIf cCampo == "N3_VRDACM5"
				AADD(aItem, {"N3_VRDACM5", VAL(aDados[i,j]), NIL})
			ElseIf cCampo == "N3_RATEIO"
				AADD(aItem, {"N3_RATEIO", aDados[i,j], NIL})
			ElseIf cCampo == "N3_SEQ"
				AADD(aItem, {"N3_SEQ", aDados[i,j], NIL})
			EndIf
		Next j

		AADD(aItens, aItem)

		// Parâmetros ExecAuto
		AADD(aParam, {"MV_PAR01", 1}) // Contabiliza? 1=Sim
		AADD(aParam, {"MV_PAR02", 2}) // Mostra Lanc Contab? 2=Nao
		AADD(aParam, {"MV_PAR03", 2}) // Aglut Lancamentos? 2=Nao

		// Executa ExecAuto ATFA012
		BEGIN SEQUENCE
			MSExecAuto({|x,y,z| Atfa012(x,y,z)}, aCab, aItens, 3, aParam)

			If lMsErroAuto
				nErros++
				cLog += "Linha " + ALLTRIM(STR(i)) + " - ERRO INCLUSÃO: "
				cLog += "Cod.Base: " + ALLTRIM(cBase) + " - "
				cLog += "Item: " + ALLTRIM(cItem) + " - "
				cLog += "Motivo: Verificar log detalhado" + CRLF
				MostraErro()
			Else
				nSucess++
				cLog += "Linha " + ALLTRIM(STR(i)) + " - OK INCLUSÃO: "
				cLog += "Cod.Base: " + ALLTRIM(cBase) + " - "
				cLog += "Item: " + ALLTRIM(cItem) + CRLF
			EndIf
		END SEQUENCE

		IncProc("Incluindo: " + cBase + "-" + cItem + " [" + ALLTRIM(STR(i)) + "/" + ALLTRIM(STR(Len(aDados))) + "]")

	Next i

Return

/*--------------------------------------------------------------------*
| Func:  V2Alterar()                                                  |
| Desc:  Alteração Cadastral via ATFA060 (Transferência)              |
|        Permite alterar: Centro de Custo, Conta Contábil, Chapinha   |
|        USA ATFA060 POIS É A FORMA RECOMENDADA PELA TOTVS            |
 *---------------------------------------------------------------------*/

Static Function V2Alterar(aCampos, aDados, nSucess, nErros, cLog)

	Local i, j
	Local cCampo
	Local aDadosAuto := {}
	Local aParamAuto := {}
	Local cBase := ""
	Local cItem := ""
	Local cTipo := ""
	Local cChapaOld := ""
	Local cChapaNew := ""
	Local cContaOld := ""
	Local cContaNew := ""
	Local cCustoOld := ""
	Local cCustoNew := ""
	Local lAchou := .F.
	Local lAchouSN3 := .F.
	Local cFilSN1 := ""
	Local cFilSN3 := ""

	ProcRegua(Len(aDados))

	For i:=1 to Len(aDados)

		lMsErroAuto := .F.
		aDadosAuto := {}
		aParamAuto := {}

		// Lê campos do CSV
		cBase := ""
		cItem := ""
		cTipo := ""
		cChapaNew := ""
		cContaNew := ""
		cCustoNew := ""

		For j:=1 to Len(aCampos)
			cCampo := AllTrim(aCampos[j])

			If cCampo == "N1_CBASE"
				cBase := aDados[i,j]
			ElseIf cCampo == "N1_ITEM"
				cItem := aDados[i,j]
			ElseIf cCampo == "N3_TIPO"
				cTipo := aDados[i,j]
			ElseIf cCampo == "N1_CHAPA"
				cChapaNew := aDados[i,j]
			ElseIf cCampo == "N3_CCONTAB"
				cContaNew := aDados[i,j]
			ElseIf cCampo == "N3_CCUSTO"
				cCustoNew := aDados[i,j]
			EndIf
		Next j

		// Validação: campos obrigatórios
		If Empty(cBase) .Or. Empty(cItem)
			nErros++
			cLog += "Linha " + ALLTRIM(STR(i)) + " - ERRO: "
			cLog += "Campos N1_CBASE e N1_ITEM são obrigatórios" + CRLF
			Loop
		EndIf

		// Validação: pelo menos um campo para alterar
		If Empty(cChapaNew) .And. Empty(cContaNew) .And. Empty(cCustoNew)
			nErros++
			cLog += "Linha " + ALLTRIM(STR(i)) + " - ERRO: "
			cLog += "Informe pelo menos um campo para alterar (Chapinha/Conta/CCusto)" + CRLF
			Loop
		EndIf

		// Verifica se o ativo existe na SN1
		cFilSN1 := xFilial("SN1")
		dbSelectArea("SN1")
		dbSetOrder(1)
		lAchou := DbSeek(cFilSN1 + PADR(cBase,TamSX3("N1_CBASE")[1]) + PADR(cItem,TamSX3("N1_ITEM")[1]))

		If !lAchou
			nErros++
			cLog += "Linha " + ALLTRIM(STR(i)) + " - ERRO: "
			cLog += "Ativo não encontrado: " + ALLTRIM(cBase) + "-" + ALLTRIM(cItem) + CRLF
			Loop
		EndIf

		// Guarda valores atuais para log
		cChapaOld := SN1->N1_CHAPA

		// Alteração da Chapinha (direto na SN1 - campo que não vai pelo ATFA060)
		If !Empty(cChapaNew) .And. AllTrim(cChapaNew) <> AllTrim(cChapaOld)
			RecLock("SN1",.F.)
			SN1->N1_CHAPA := cChapaNew
			SN1->(MsUnlock())
			cLog += "Linha " + ALLTRIM(STR(i)) + " - CHAPINHA alterada: " + ALLTRIM(cChapaOld) + " ? " + ALLTRIM(cChapaNew) + CRLF

			// Se não há alteração contábil nesta linha, a chapinha já fecha o sucesso da linha
			If Empty(cContaNew) .And. Empty(cCustoNew)
				nSucess++
			EndIf
		EndIf

		// Alteração de Entidades Contábeis via ATFA060 (Transferência)
		If !Empty(cContaNew) .Or. !Empty(cCustoNew)

			// Busca dados atuais da SN3
			cFilSN3 := xFilial("SN3")
			dbSelectArea("SN3")
			dbSetOrder(1) // N3_FILIAL + N3_CBASE + N3_ITEM + N3_TIPO + N3_BAIXA + N3_SEQ

			If Empty(cTipo)
				cTipo := "01" // Tipo padrão
			EndIf

			lAchouSN3 := DbSeek(cFilSN3 + PADR(cBase,TamSX3("N3_CBASE")[1]) + PADR(cItem,TamSX3("N3_ITEM")[1]) + PADR(cTipo,TamSX3("N3_TIPO")[1]))

			If !lAchouSN3
				nErros++
				cLog += "Linha " + ALLTRIM(STR(i)) + " - ERRO: "
				cLog += "Registro SN3 não encontrado para: " + ALLTRIM(cBase) + "-" + ALLTRIM(cItem) + " Tipo: " + ALLTRIM(cTipo) + CRLF
				Loop
			EndIf

			// Guarda valores atuais
			cContaOld := SN3->N3_CCONTAB
			cCustoOld := SN3->N3_CCUSTO

			// Monta array para ATFA060 (Transferência Contábil)
			aDadosAuto := {}
			AADD(aDadosAuto, {"N3_FILIAL" , cFilSN3                                    , Nil})
			AADD(aDadosAuto, {"N3_CBASE"  , cBase                                      , Nil})
			AADD(aDadosAuto, {"N3_ITEM"   , cItem                                      , Nil})
			AADD(aDadosAuto, {"N3_TIPO"   , cTipo                                      , Nil})
			AADD(aDadosAuto, {"N4_DATA"   , dDatabase                                  , Nil})

			// Entidades de DESTINO (campos a serem alterados)
			AADD(aDadosAuto, {"N3_CCUSTO" , IIF(!Empty(cCustoNew), cCustoNew, cCustoOld), Nil})
			AADD(aDadosAuto, {"N3_CCONTAB", IIF(!Empty(cContaNew), cContaNew, cContaOld), Nil})

			// Demais entidades mantém os valores atuais
			AADD(aDadosAuto, {"N3_CCORREC", SN3->N3_CCORREC                             , Nil})
			AADD(aDadosAuto, {"N3_CDEPREC", SN3->N3_CDEPREC                             , Nil})
			AADD(aDadosAuto, {"N3_CDESP"  , SN3->N3_CDESP                               , Nil})
			AADD(aDadosAuto, {"N3_CUSTBEM", SN3->N3_CUSTBEM                             , Nil})
			AADD(aDadosAuto, {"N3_CCCORR" , SN3->N3_CCCORR                              , Nil})
			AADD(aDadosAuto, {"N3_CCDESP" , SN3->N3_CCDESP                              , Nil})
			AADD(aDadosAuto, {"N3_CCCDEP" , SN3->N3_CCCDEP                              , Nil})
			AADD(aDadosAuto, {"N3_CCCDES" , SN3->N3_CCCDES                              , Nil})
			AADD(aDadosAuto, {"N1_GRUPO"  , SN1->N1_GRUPO                               , Nil})
			AADD(aDadosAuto, {"N1_LOCAL"  , SN1->N1_LOCAL                               , Nil})
			AADD(aDadosAuto, {"N1_NFISCAL", SN1->N1_NFISCAL                             , Nil})
			AADD(aDadosAuto, {"N1_NSERIE" , SN1->N1_NSERIE                              , Nil})
			AADD(aDadosAuto, {"N1_TAXAPAD", SN1->N1_TAXAPAD                             , Nil})

			// Parâmetros ATFA060
			aAdd(aParamAuto, {"MV_PAR01", 1}) // Contabiliza? 1=Sim
			aAdd(aParamAuto, {"MV_PAR02", 2}) // Mostra Lanc Contab? 2=Nao
			aAdd(aParamAuto, {"MV_PAR03", 2}) // Aglut Lancamentos? 2=Nao

			// Executa ATFA060 (Transferência Contábil)
			BEGIN SEQUENCE
				MSExecAuto({|x, y, w, z| AtfA060(x, y, w, z)}, aDadosAuto, 4, aParamAuto, .F.)

				If lMsErroAuto
					nErros++
					cLog += "Linha " + ALLTRIM(STR(i)) + " - ERRO ALTERAÇÃO: "
					cLog += "Cod.Base: " + ALLTRIM(cBase) + " - "
					cLog += "Item: " + ALLTRIM(cItem) + " - "
					cLog += "Motivo: Verificar log detalhado" + CRLF
					MostraErro()
				Else
					nSucess++
					cLog += "Linha " + ALLTRIM(STR(i)) + " - OK ALTERAÇÃO: "
					cLog += "Cod.Base: " + ALLTRIM(cBase) + " - "
					cLog += "Item: " + ALLTRIM(cItem)
					If !Empty(cContaNew)
						cLog += " | Conta: " + ALLTRIM(cContaOld) + " ? " + ALLTRIM(cContaNew)
					EndIf
					If !Empty(cCustoNew)
						cLog += " | CCusto: " + ALLTRIM(cCustoOld) + " ? " + ALLTRIM(cCustoNew)
					EndIf
					cLog += CRLF
				EndIf
			END SEQUENCE

		EndIf

		IncProc("Alterando: " + cBase + "-" + cItem + " [" + ALLTRIM(STR(i)) + "/" + ALLTRIM(STR(Len(aDados))) + "]")

	Next i

Return

