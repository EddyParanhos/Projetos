#INCLUDE 'RWMAKE.CH'
#INCLUDE "Topconn.ch"
#INCLUDE "TBICONN.ch"
#INCLUDE "Protheus.ch"
#INCLUDE "REPORT.CH"

/*--------------------------------------------------------------------*
| Func:  IMPTABERP()                                                  |
| Autor: Edmar Paranhos                                               |
| Data:  29/11/2022                                                   |
| Desc:  Barra de processo / Leitura do Arquivo.                      |
| Obs.:  Uso generico - estudo                                 |
*---------------------------------------------------------------------*/

User Function ImpTabErp()

	Processa({|| U_ImpErpSx()}, "Lendo Arquivo .CSV")

Return

/*--------------------------------------------------------------------*
| Func:  ImpErpSx()                                                   |
| Autor: Edmar Paranhos                                               |
| Data:  29/11/2022                                                   |
| Desc:  Importa Arquivos .CSV                                        |
| Obs.:  Uso generico - estudo                                 |
*---------------------------------------------------------------------*/

User Function ImpErpSx()

/*
Informe em cada coluna o nome técnico do campo da tabela, exemplo: B1_FILIAL;B1_COD;B1_DESC;
*/
Local oDlg
Local oFont
Local oFont1, oFont2
Local oFolder
Local nOpct  := 2
Local cLinha := ""
Local lPrim := .T.
Local aCampos := {}
Local aDados := {}
Local cCampo
Local cTabImp := ""
Local cArqNome := ""
Local cCmbTab := ""
Local aCmbTab:= {'SF7=Exceção Fiscal','SFM=TES Inteligente','SB1=Produtos','SB9=Sld.Iniciais','SA1=Clientes','SA2=Fornecedores','AI3=Usr.portal','AI5=Forn.Portal'}
Local nOpc1	    := 0
Local cQuery
Local cIDxSFM := ""
Local nAtual := 50
Private cArqCSV := Space(40)
Private aErro := {}

Define MSDialog oDlg Title "Manutenção de Cadastros" From 0,0 To 180,400 Pixel STYLE DS_MODALFRAME

//Seleção de Tabelas.
@ 015,030 say "Selecionar Tabela:" Pixel Of oDlg COLOR CLR_HBLUE
@ 014,080 ComboBox cCmbTab ITEMS aCmbTab SIZE 80,10 Size 50,10 VALID(!EMPTY(cCmbTab)) when .T. pixel


@055,040 BUTTON "Imp.Arquivo" SIZE 55 ,15    FONT oDlg:oFont  OF oDlg PIXEL  ACTION (cArqNome:=cGetFile("Arquivo CSV|*.CSV", "Seleção dos Arquivos"),ODlg:End())
@055,110 BUTTON "Cancelar"    SIZE 55 ,15    FONT oDlg:oFont  OF oDlg PIXEL  ACTION (nOpct:=2,ODlg:End())

oDlg:lEscClose := .F.

Activate MSDialog oDlg Centered

If !File(cArqNome)
	MsgStop("O arquivo " +cArqNome+ " não foi selecionado. A importação será finalizada!","[ImpTabErp] - ATENCAO")
Return
EndIf

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

	IncProc("Arquivo Selecionado: "+cArqNome)

	FT_FSKIP()
EndDo

Begin Transaction
	ProcRegua(Len(aDados))
	For i:=1 to Len(aDados)

		If cCmbTab == "SFM"

			cQuery := "SELECT DISTINCT SFM.R_E_C_N_O_,FM_FILIAL,FM_TIPO,FM_CLIENTE,FM_LOJACLI,FM_FORNECE,FM_LOJAFOR,FM_GRTRIB,FM_PRODUTO,FM_GRPROD,FM_EST,FM_POSIPI,FM_ID"+ CRLF
			cQuery += " FROM "+RetSqlName("SFM")+" SFM "+ CRLF
			cQuery += " WHERE FM_TIPO = '"+aDados[i,2]+"'"+ CRLF
			cQuery += " AND FM_CLIENTE = '"+aDados[i,3]+"'"+ CRLF
			cQuery += " AND FM_LOJACLI = '"+aDados[i,4]+"'"+ CRLF
			cQuery += " AND FM_FORNECE = '"+aDados[i,5]+"'"+ CRLF
			cQuery += " AND FM_LOJAFOR = '"+aDados[i,6]+"'"+ CRLF
			cQuery += " AND FM_GRTRIB = '"+aDados[i,7]+"'"+ CRLF
			cQuery += " AND FM_PRODUTO = '"+aDados[i,8]+"'"+ CRLF
			cQuery += " AND FM_GRPROD = '"+aDados[i,9]+"'"+ CRLF
			cQuery += " AND FM_EST = '"+aDados[i,10]+"'"+ CRLF
			cQuery += " AND FM_POSIPI = '"+aDados[i,11]+"'"+ CRLF
			cQuery += " AND FM_TE = '"+aDados[i,12]+"'"+ CRLF // Inclusão do TES Entrada
			cQuery += " AND FM_TS = '"+aDados[i,13]+"'"+ CRLF // Inclusão do TES Saida
			cQuery += " AND FM_GRPTI = '"+aDados[i,15]+"'"+ CRLF // Inclusão do Grupo-TI
			cQuery += " AND SFM.D_E_L_E_T_ = '' " + CRLF

			cQuery := ChangeQuery(cQuery)

			TcQuery cQuery New Alias "QRYSFM"

			cIDxSFM := QRYSFM->FM_ID

			//Alteração de registros Já existentes
			dbSelectArea("SFM")
			dbSetOrder(3)

			If DbSeek(SFM->FM_FILIAL+cIDxSFM)

				RecLock("SFM",.F.)

				SFM->FM_FILIAL := aDados[i,1]
				For j:=1 to Len(aCampos)
					cCampo := "SFM->" + aCampos[j]
					If ValType(&cCampo) == "D"
						&cCampo := Ctod(aDados[i,j])
					ElseIf ValType(&cCampo) == "N"
						&cCampo := Val(aDados[i,j])
					Else
						&cCampo := aDados[i,j]
					EndIf
				Next j
				SFM-> (MsUnlock())

			Endif

			If !DbSeek(SFM->FM_FILIAL+cIDxSFM) //Seta o ID da SFM.

				//Inclusão de registros não existentes

				RecLock("SFM",.T.)

				SFM->FM_ID := GetSxeNum("SFM","FM_ID")

				SFM->FM_FILIAL := aDados[i,1]
				For j:=1 to Len(aCampos)
					cCampo := "SFM->" + aCampos[j]
					If ValType(&cCampo) == "D"
						&cCampo := Ctod(aDados[i,j])
					ElseIf ValType(&cCampo) == "N"
						&cCampo := Val(aDados[i,j])
					Else
						&cCampo := aDados[i,j]
					EndIf
				Next j
				SFM-> (MsUnlock())
			EndIf

			QRYSFM->(DbCloseArea())
		Endif

		If cCmbTab == "SF7"

			//Alteração de registros Já existentes
			dbSelectArea("SF7")
			dbSetOrder(3)

			If DbSeek(SF7->F7_FILIAL + aDados[i,2] + aDados[i,3])

				RecLock("SF7",.F.)

				SF7->F7_FILIAL := aDados[i,1]
				For j:=1 to Len(aCampos)
					cCampo := "SF7->" + aCampos[j]
					If ValType(&cCampo) == "D"
						&cCampo := Ctod(aDados[i,j])
					ElseIf ValType(&cCampo) == "N"
						&cCampo := Val(aDados[i,j])
					Else
						&cCampo := aDados[i,j]
					EndIf
				Next j
				SF7-> (MsUnlock())

			Endif

			If !DbSeek(SF7->F7_FILIAL + aDados[i,2] + aDados[i,3])

				//Inclusão de registros não existentes

				RecLock("SF7",.T.)

				SF7->F7_FILIAL := aDados[i,1]
				For j:=1 to Len(aCampos)
					cCampo := "SF7->" + aCampos[j]
					If ValType(&cCampo) == "D"
						&cCampo := Ctod(aDados[i,j])
					ElseIf ValType(&cCampo) == "N"
						&cCampo := Val(aDados[i,j])
					Else
						&cCampo := aDados[i,j]
					EndIf
				Next j
				SF7-> (MsUnlock())
			EndIf
		Endif

		If cCmbTab == "SB1"

			//Alteração de registros Já existentes
			dbSelectArea("SB1")
			dbSetOrder(1)

			If DbSeek(SB1->B1_FILIAL + aDados[i,2])

				RecLock("SB1",.F.)

				SB1->B1_FILIAL := aDados[i,1]
				For j:=1 to Len(aCampos)
					cCampo := "SB1->" + aCampos[j]
					If ValType(&cCampo) == "D"
						&cCampo := Ctod(aDados[i,j])
					ElseIf ValType(&cCampo) == "N"
						&cCampo := Val(aDados[i,j])
					Else
						&cCampo := aDados[i,j]
					EndIf
				Next j
				SB1-> (MsUnlock())

			Endif

			If !DbSeek(SB1->B1_FILIAL + aDados[i,2])

			//Inclusão de registros não existentes

				RecLock("SB1",.T.)

				SB1->B1_FILIAL := aDados[i,1]
				For j:=1 to Len(aCampos)
					cCampo := "SB1->" + aCampos[j]
					If ValType(&cCampo) == "D"
						&cCampo := Ctod(aDados[i,j])
					ElseIf ValType(&cCampo) == "N"
						&cCampo := Val(aDados[i,j])
					Else
						&cCampo := aDados[i,j]
					EndIf
				Next j
				SB1-> (MsUnlock())
			EndIf

		Endif

		If cCmbTab == "SB9"

			//B9_FILIAL + B9_COD + B9_LOCAL + DTOS(B9_DATA)
			//Alteração de registros Já existentes
			dbSelectArea("SB9")
			dbSetOrder(1)

			If DbSeek(SB9->B9_FILIAL + aDados[i,2]+ aDados[i,3]+ aDados[i,4])

				RecLock("SB9",.F.)

				SB9->B9_FILIAL := aDados[i,1]
				For j:=1 to Len(aCampos)
					cCampo := "SB9->" + aCampos[j]
					If ValType(&cCampo) == "D"
						&cCampo := Ctod(aDados[i,j])
					ElseIf ValType(&cCampo) == "N"
						&cCampo := Val(aDados[i,j])
					Else
						&cCampo := aDados[i,j]
					EndIf
				Next j
				SB9-> (MsUnlock())

			Endif

			If !DbSeek(SB9->B9_FILIAL + aDados[i,2]+ aDados[i,3]+ aDados[i,4])

			//Inclusão de registros não existentes

				RecLock("SB9",.T.)

				SB9->B9_FILIAL := aDados[i,1]
				For j:=1 to Len(aCampos)
					cCampo := "SB9->" + aCampos[j]
					If ValType(&cCampo) == "D"
						&cCampo := Ctod(aDados[i,j])
					ElseIf ValType(&cCampo) == "N"
						&cCampo := Val(aDados[i,j])
					Else
						&cCampo := aDados[i,j]
					EndIf
				Next j
				SB9-> (MsUnlock())
			EndIf

		Endif

		If cCmbTab == "SA1"

			//Alteração de registros Já existentes
			//A1_FILIAL+A1_COD+A1_LOJA                                                                                                                                        
			dbSelectArea("SA1")
			dbSetOrder(1)

			If DbSeek(SA1->A1_FILIAL + aDados[i,2]+ aDados[i,3])

				RecLock("SA1",.F.)

				SA1->A1_FILIAL := aDados[i,1]
				For j:=1 to Len(aCampos)
					cCampo := "SA1->" + aCampos[j]
					If ValType(&cCampo) == "D"
						&cCampo := Ctod(aDados[i,j])
					ElseIf ValType(&cCampo) == "N"
						&cCampo := Val(aDados[i,j])
					Else
						&cCampo := aDados[i,j]
					EndIf
				Next j
				SA1-> (MsUnlock())

			Endif
	Endif
	
	If cCmbTab == "SA2"

			//Alteração de registros Já existentes
			//A2_FILIAL+A2_COD+A2_LOJA                                                                                                                                        
			dbSelectArea("SA2")
			dbSetOrder(1)

			If DbSeek(SA2->A2_FILIAL + aDados[i,2]+ aDados[i,3])

				RecLock("SA2",.F.)

				SA2->A2_FILIAL := aDados[i,1]
				For j:=1 to Len(aCampos)
					cCampo := "SA2->" + aCampos[j]
					If ValType(&cCampo) == "D"
						&cCampo := Ctod(aDados[i,j])
					ElseIf ValType(&cCampo) == "N"
						&cCampo := Val(aDados[i,j])
					Else
						&cCampo := aDados[i,j]
					EndIf
				Next j
				SA2-> (MsUnlock())

			Endif

			If !DbSeek(SA2->A2_FILIAL + aDados[i,2]+ aDados[i,3])

			//Inclusão de registros não existentes

				RecLock("SA2",.T.)

				SA2->A2_FILIAL := aDados[i,1]
				For j:=1 to Len(aCampos)
					cCampo := "SA2->" + aCampos[j]
					If ValType(&cCampo) == "D"
						&cCampo := Ctod(aDados[i,j])
					ElseIf ValType(&cCampo) == "N"
						&cCampo := Val(aDados[i,j])
					Else
						&cCampo := aDados[i,j]
					EndIf
				Next j
				SA2-> (MsUnlock())
			EndIf

		Endif

	If cCmbTab == "AI3"

			//Alteração de registros Já existentes
			//AI3_FILIAL+AI3_CODUSU                                                                                                                                                                                                                                                                                   
			dbSelectArea("AI3")
			dbSetOrder(1)

			If DbSeek(AI3->AI3_FILIAL + aDados[i,2])

				RecLock("AI3",.F.)

				AI3->AI3_FILIAL := aDados[i,1]
				For j:=1 to Len(aCampos)
					cCampo := "AI3->" + aCampos[j]
					If ValType(&cCampo) == "D"
						&cCampo := Ctod(aDados[i,j])
					ElseIf ValType(&cCampo) == "N"
						&cCampo := Val(aDados[i,j])
					Else
						&cCampo := aDados[i,j]
					EndIf
				Next j
				AI3-> (MsUnlock())

			Endif

			If !DbSeek(AI3->AI3_FILIAL + aDados[i,2])

			//Inclusão de registros não existentes

				RecLock("AI3",.T.)

				AI3->AI3_FILIAL := aDados[i,1]
				For j:=1 to Len(aCampos)
					cCampo := "AI3->" + aCampos[j]
					If ValType(&cCampo) == "D"
						&cCampo := Ctod(aDados[i,j])
					ElseIf ValType(&cCampo) == "N"
						&cCampo := Val(aDados[i,j])
					Else
						&cCampo := aDados[i,j]
					EndIf
				Next j
				AI3-> (MsUnlock())
			EndIf

		Endif

	If cCmbTab == "AI5"

			//Alteração de registros Já existentes
			//AI5_FILIAL+AI5_CODUSU                                                                                                                                                                                                                                                                                   
			dbSelectArea("AI5")
			dbSetOrder(1)

			If DbSeek(AI5->AI5_FILIAL + aDados[i,2])

				RecLock("AI5",.F.)

				AI5->AI5_FILIAL := aDados[i,1]
				For j:=1 to Len(aCampos)
					cCampo := "AI5->" + aCampos[j]
					If ValType(&cCampo) == "D"
						&cCampo := Ctod(aDados[i,j])
					ElseIf ValType(&cCampo) == "N"
						&cCampo := Val(aDados[i,j])
					Else
						&cCampo := aDados[i,j]
					EndIf
				Next j
				AI5-> (MsUnlock())

			Endif

			If !DbSeek(AI5->AI5_FILIAL + aDados[i,2])

			//Inclusão de registros não existentes

				RecLock("AI5",.T.)

				AI5->AI5_FILIAL := aDados[i,1]
				For j:=1 to Len(aCampos)
					cCampo := "AI5->" + aCampos[j]
					If ValType(&cCampo) == "D"
						&cCampo := Ctod(aDados[i,j])
					ElseIf ValType(&cCampo) == "N"
						&cCampo := Val(aDados[i,j])
					Else
						&cCampo := aDados[i,j]
					EndIf
				Next j
				AI5-> (MsUnlock())
			EndIf

		Endif


		nAtual++

		If cCmbTab == "SFM"
			IncProc("Importando Tp. Operação: "+aDados[i,2]+"-"+aDados[i,14])
		Endif

		If cCmbTab == "SF7"
			IncProc("Importando Grupo Trib.: "+aDados[i,2]+"-"+aDados[i,4])
		Endif

		If cCmbTab == "SB1"
			IncProc("Importando Cód. Produto: "+aDados[i,2] + "-" +aDados[i,3] )
		Endif

		If cCmbTab == "SB9"
			IncProc("Importando Cód. Produto: "+aDados[i,2] + "- Armazem: " +aDados[i,3] )
		Endif

		If cCmbTab $ "SA1/SA2"
			IncProc("Importando Cliente/Fornecedor: "+aDados[i,2])
		Endif

		If cCmbTab $ "AI3/AI5"
			IncProc("Importando Fornecedor Portal: "+aDados[i,2])
		Endif


	Next i

End Transaction

FT_FUSE()

ApMsgInfo("Manutenção cadastral realizada!","SUCESSO.")

Return
