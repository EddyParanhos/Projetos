#INCLUDE 'RWMAKE.CH'
#INCLUDE "Topconn.ch"
#INCLUDE "TBICONN.ch"
#INCLUDE "Protheus.ch"
#INCLUDE "REPORT.CH"

/*--------------------------------------------------------------------*
| Func:  ImpTbVMT()                                                   |
| Autor: Edmar Paranhos                                               |
| Data:  18/12/2023                                                   |
| Desc:  Barra de processo / Leitura do Arquivo.                      |
| Obs.:  Especifico COMM                                              |
| ATENCAO: A partir de 08/2026, SN1/SN3 (Ativos) NAO sao mais         |
|          importados por aqui. Use ATFExecV2() (ATF_ExecAuto_v2.prw),|
|          que valida duplicidade na inclusao e restringe a alteracao |
|          a CCusto/Conta Contabil/Chapinha via ExecAuto (ATFA012/    |
|          ATFA060). As opcoes SN1/SN3 foram removidas do combo       |
|          abaixo para evitar sobreposicao indevida de cadastro.      |
*---------------------------------------------------------------------*/

User Function ImpTbVMT()

	Processa({|| U_ImpErpSx()}, "Lendo Arquivo .CSV")

Return

/*--------------------------------------------------------------------*
| Func:  ImpErpSx()                                                   |
| Autor: Edmar Paranhos                                               |
| Data:  18/12/2023                                                   |
| Desc:  Importa Arquivos .CSV                                        |
| Obs.:  Especifico COMM                                              |
*---------------------------------------------------------------------*/

User Function ImpErpSx()

/*
Informe em cada coluna o nome t�cnico do campo da tabela, exemplo: B1_FILIAL;B1_COD;B1_DESC;
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
Local aCmbTab:= {'SA5=Prod.X.Forn.','CTJ=Rateio','F3K=Itens x Cod.Val.Declar'} //SN1/SN3 removidos - ver ATFExecV2()
Local nOpc1	 := 0
Local cQuery
Local nAtual := 50
Private cArqCSV := Space(40)
Private aErro := {}
//U_XFUNLOG()
Define MSDialog oDlg Title "Importa��o de Tabelas" From 0,0 To 180,400 Pixel STYLE DS_MODALFRAME

//Sele��o de Tabelas.
@ 015,030 say "Selecionar Tabela:" Pixel Of oDlg COLOR CLR_HBLUE
@ 014,080 ComboBox cCmbTab ITEMS aCmbTab SIZE 80,10 Size 50,10 VALID(!EMPTY(cCmbTab)) when .T. pixel


@055,040 BUTTON "Imp.Arquivo" SIZE 55 ,15    FONT oDlg:oFont  OF oDlg PIXEL  ACTION (cArqNome:=cGetFile("Arquivo CSV|*.CSV", "Sele��o dos Arquivos"),ODlg:End())
@055,110 BUTTON "Cancelar"    SIZE 55 ,15    FONT oDlg:oFont  OF oDlg PIXEL  ACTION (nOpct:=2,ODlg:End())

oDlg:lEscClose := .F.

Activate MSDialog oDlg Centered

If !File(cArqNome)
	MsgStop("O arquivo " +cArqNome+ " n�o foi selecionado. A importa��o ser� finalizada!","[ImpTbVMT] - ATENCAO")
Return
EndIf

FT_FUSE(cArqNome)
ProcRegua(FT_FLASTREC())
FT_FGOTOP()
While !FT_FEOF()

	cLinha := FT_FREADLN()

	If lPrim
		aCampos := Separa(cLinha,";",.T.) //O separador � Ponto e Virgula
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

		//SN1/SN3 (Ativos) removidos deste ponto em diante - usar ATFExecV2() (ATF_ExecAuto_v2.prw)

		If cCmbTab == "SA5"

			//Altera��o de registros J� existentes
			dbSelectArea("SA5")
			dbSetOrder(1)

			//A5_FILIAL+A5_PRODUTO+A5_FORNECE+A5_LOJA    

			lExiste := SA5->(dbSeek(xFilial("SA5")+aDados[i,2]+aDados[i,3]+aDados[i,5]))

			If lExiste == .T. //DbSeek(aDados[i,2] + aDados[i,3] + aDados[i,5])

				RecLock("SA5",.F.)

					SA5->A5_FILIAL := aDados[i,1]
					For j:=1 to Len(aCampos)
						cCampo := "SA5->" + aCampos[j]
						If ValType(&cCampo) == "D"
							&cCampo := Ctod(aDados[i,j])
						ElseIf ValType(&cCampo) == "N"
							&cCampo := Val(aDados[i,j])
						Else
							&cCampo := aDados[i,j]
						EndIf
					Next j
					SA5-> (MsUnlock())

			Endif

			If lExiste == .F. 
					//If !DbSeek(aDados[i,2] + aDados[i,3] + aDados[i,5])

					//Inclus�o de registros n�o existentes

					RecLock("SA5",.T.)

					SA5->A5_FILIAL := aDados[i,1]
					For j:=1 to Len(aCampos)
						cCampo := "SA5->" + aCampos[j]
						If ValType(&cCampo) == "D"
							&cCampo := Ctod(aDados[i,j])
						ElseIf ValType(&cCampo) == "N"
							&cCampo := Val(aDados[i,j])
						Else
							&cCampo := aDados[i,j]
						EndIf
					Next j
					SA5-> (MsUnlock())
			EndIf
		Endif

		//Inclus�o do Rateio Externo - 19/01/2026

		If cCmbTab == "CTJ"

			//CTJ_FILIAL + CTJ_RATEIO + CTJ_SEQUEN                                                                                                                                                                                                                                                                                                                                                
			//Altera��o de registros J� existentes
			dbSelectArea("CTJ")
			dbSetOrder(1) //Indice 1
			DbGoTop()

			If DbSeek(aDados[i,1] + aDados[i,2] + aDados[i,7])

				RecLock("CTJ",.F.)

				CTJ->CTJ_FILIAL := aDados[i,1]
				For j:=1 to Len(aCampos)
					cCampo := "CTJ->" + aCampos[j]
					If ValType(&cCampo) == "D"
						&cCampo := Ctod(aDados[i,j])
					ElseIf ValType(&cCampo) == "N"
						&cCampo := Val(aDados[i,j])
					Else
						&cCampo := aDados[i,j]
					EndIf
				Next j
				CTJ-> (MsUnlock())

			Endif

			If !DbSeek(aDados[i,1] + aDados[i,2] + aDados[i,7])

			//Inclus�o de registros n�o existentes

				RecLock("CTJ",.T.)

				CTJ->CTJ_FILIAL := aDados[i,1]
				For j:=1 to Len(aCampos)
					cCampo := "CTJ->" + aCampos[j]
					If ValType(&cCampo) == "D"
						&cCampo := Ctod(aDados[i,j])
					ElseIf ValType(&cCampo) == "N"
						&cCampo := Val(aDados[i,j])
					Else
						&cCampo := aDados[i,j]
					EndIf
				Next j
				CTJ-> (MsUnlock())
			EndIf

		Endif

		//Inclus�o da F3K - Itens x Cod.Val.Declaratorios - 22/07/2026

		If cCmbTab == "F3K"

			//F3K_FILIAL+F3K_PROD+F3K_CFOP+F3K_CST (Indice 2)
			//Altera��o de registros j� existentes
			dbSelectArea("F3K")
			dbSetOrder(2) //Indice 2

			If DbSeek(aDados[i,1] + aDados[i,2] + aDados[i,3] + aDados[i,5])

				RecLock("F3K",.F.)

				F3K->F3K_FILIAL := aDados[i,1]
				For j:=1 to Len(aCampos)
					cCampo := "F3K->" + aCampos[j]
					If ValType(&cCampo) == "D"
						&cCampo := Ctod(aDados[i,j])
					ElseIf ValType(&cCampo) == "N"
						&cCampo := Val(aDados[i,j])
					Else
						&cCampo := aDados[i,j]
					EndIf
				Next j
				F3K-> (MsUnlock())

			Endif

			If !DbSeek(aDados[i,1] + aDados[i,2] + aDados[i,3] + aDados[i,5])

			//Inclus�o de registros n�o existentes

				RecLock("F3K",.T.)

				F3K->F3K_FILIAL := aDados[i,1]
				For j:=1 to Len(aCampos)
					cCampo := "F3K->" + aCampos[j]
					If ValType(&cCampo) == "D"
						&cCampo := Ctod(aDados[i,j])
					ElseIf ValType(&cCampo) == "N"
						&cCampo := Val(aDados[i,j])
					Else
						&cCampo := aDados[i,j]
					EndIf
				Next j
				F3K-> (MsUnlock())
			EndIf

		Endif

		nAtual++

		If cCmbTab == "SA5"
			IncProc("Importando Prod.: "+aDados[i,5] + "-" +aDados[i,6] )
		Endif

		If cCmbTab == "CTJ"
			IncProc("Importando Rateio.: "+aDados[i,2] + "-" +aDados[i,7] )
		Endif

		If cCmbTab == "F3K"
			IncProc("Importando Val.Declar.: "+aDados[i,2] + "-" +aDados[i,3] )
		Endif


	Next i

End Transaction

FT_FUSE()

ApMsgInfo("Importa��o realizada!","SUCESSO.")

Return
