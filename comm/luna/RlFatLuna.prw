#Include "Protheus.ch"
#Include "TOTVS.ch"
#Include "REPORT.ch"
#Include "TBICONN.CH"
#Include "Topconn.ch"

/*---------------------------------------------------------------------*
| Func:  RlFatLuna()                                                  |
| Autor: Edmar Paranhos                                               |
| Data:  03/07/2026                                                   |
| Desc:  Relatorio de Faturamento (SD2) com Chave da NF-e (SF2).      |
| Obs.:  Join SD2->SA1 (cliente), SD2->SB1 (produto), SD2->SF2        |
|        (chave NF-e). Parametros: Emissao De/Ate e Filial De/Ate.    |
*---------------------------------------------------------------------*/

User Function RlFatLuna()

	//+---------------------------------------------------------+
	//| Declaracao de variaveis                                 |
	//+---------------------------------------------------------+

	Private oReport    := Nil
	Private oSection01 := Nil

	//+---------------------------------------------------------+
	//| Definicoes/preparacao para impressao                    |
	//+---------------------------------------------------------+

	ReportDef()
	oReport:PrintDialog()

Return Nil

/*---------------------------------------------------------------------*
| Func:  ReportDef                                                    |
| Autor: Edmar Paranhos                                               |
| Data:  03/07/2026                                                   |
| Desc:  Definicao da estrutura do relatorio.                         |
*---------------------------------------------------------------------*/

Static Function ReportDef()

	Private cPerg := "RlFatLuna"

	AjustaSX1()

	oReport := TReport():New( ;
		'RlFatLuna'                                      ,;  // ID interno
		'Relatorio de Faturamento - LUNA'                 ,;  // Titulo
		'RlFatLuna'                                       ,;  // Grupo SX1
		{|oReport| PrintReport(oReport)}                 ,;  // Block impressao
		'Faturamento / NF-e'      )                          // Descricao

	oReport:SetLandscape()  // Paisagem - necessario pelo numero de colunas

	oSection01 := TRSection():New(oReport, 'Faturamento', ,, .F., .T.)

	// --- Identificacao do documento ---
	TRCell():New(oSection01, 'FILIAL'   ,, 'Filial'      ,, 04)
	TRCell():New(oSection01, 'EMISSAO'  ,, 'Emissao'     ,, 09)
	TRCell():New(oSection01, 'NUM_ORCA' ,, 'Num.Or�amento',, 15)
	TRCell():New(oSection01, 'NFDOC'    ,, 'Nota Fiscal' ,, 10)
	TRCell():New(oSection01, 'SERIE'    ,, 'Serie'       ,, 04)
	TRCell():New(oSection01, 'CFOP'     ,, 'CFOP'        ,, 06)
	TRCell():New(oSection01, 'CLIENTE'  ,, 'Cliente'     ,, 06)
	TRCell():New(oSection01, 'LOJA'     ,, 'Loja'        ,, 04)
	TRCell():New(oSection01, 'NOMECLI'  ,, 'Nome Cliente',, 30)
	TRCell():New(oSection01, 'PRODUTO'  ,, 'Cod.Produto' ,, 15)
	TRCell():New(oSection01, 'DESCPRD'  ,, 'Descr.Produto',, 30)
	TRCell():New(oSection01, 'TES'      ,, 'TES'         ,, 05)
	TRCell():New(oSection01, 'TIPO'     ,, 'TIPO'        ,, 05)
	TRCell():New(oSection01, 'FORMPAG'  ,, 'Forma PGTO'  ,, 20)
	//Inclus�o das novas Colunas SE1
	TRCell():New(oSection01, 'CARTAUT'  ,,'Autoriz.'     ,, 40)
	TRCell():New(oSection01, 'DOCTEF'   ,,'Doc.TEF'      ,, 20)
	TRCell():New(oSection01, 'NSUTEF'   ,,'NSU'          ,, 40)
	TRCell():New(oSection01, 'VEND_TEF' ,, 'Venda TEF?'  ,, 05)
	// --- Valores do documento ---
	TRCell():New(oSection01, 'VLRTOTAL' ,, 'Vlr.Total'     ,, 14, ,, '@E 999,999,999.99')
	TRCell():New(oSection01, 'VLRICM'   ,, 'Vlr.ICMS'      ,, 12, ,, '@E 999,999,999.99')
	TRCell():New(oSection01, 'VLRPIS'   ,, 'Vlr.PIS'       ,, 12, ,, '@E 999,999,999.99')
	TRCell():New(oSection01, 'VLRCOF'   ,, 'Vlr.COFINS'    ,, 12, ,, '@E 999,999,999.99')

	// --- Chave de acesso ---
	TRCell():New(oSection01, 'CHVNFE'   ,, 'Chave NF-e'  ,, 44)

Return Nil

/*---------------------------------------------------------------------*
| Func:  PrintReport                                                  |
| Autor: Edmar Paranhos                                               |
| Data:  03/07/2026                                                   |
| Desc:  Monta a query e imprime a secao do relatorio.                |
*---------------------------------------------------------------------*/

Static Function PrintReport(oReport)

	Local cQuery  := ""
	Local cAlias  := GetNextAlias()
	Local cFilDe  := MV_PAR03
	Local cFilAte := MV_PAR04
	Local dDtDe   := MV_PAR01
	Local dDtAte  := MV_PAR02

	oSection01 := oReport:Section(1)

	cQuery := " SELECT "                                                                           + CRLF
	cQuery += "     D2.D2_FILIAL                                        AS FILIAL,   "             + CRLF
	cQuery += "     D2.D2_EMISSAO                                       AS EMISSAO,  "             + CRLF
	cQuery += "     D2.D2_DOC                                           AS NF_DOC,   "             + CRLF
	cQuery += "     D2.D2_SERIE                                         AS NF_SERIE, "             + CRLF
	cQuery += "     D2.D2_CF                                            AS CFOP,     "             + CRLF
	cQuery += "     D2.D2_CLIENTE                                       AS CLIENTE,  "             + CRLF
	cQuery += "     D2.D2_LOJA                                          AS LOJA,     "             + CRLF
	cQuery += "     RTRIM(SA1.A1_NREDUZ)                                AS NOME_CLI, "             + CRLF
	cQuery += "     D2.D2_COD                                           AS PRODUTO,  "             + CRLF
	cQuery += "     SB1.B1_DESC                                         AS DESC_PRD, "             + CRLF
    cQuery += "     SE1.E1_TIPO                                         AS TIPO_PAG, "             + CRLF
    cQuery += "     SE1.E1_NOMCLI                                       AS NOME_PAG, "             + CRLF
	cQuery += "     SE1.E1_CARTAUT                                      AS CARTAUT,  "             + CRLF
	cQuery += "     SE1.E1_DOCTEF                                       AS DOCTEF,   "             + CRLF
	cQuery += "     SE1.E1_NSUTEF                                       AS NSUTEF,   "             + CRLF
	cQuery += "     SLX.L2_NUM                                          AS NUM_ORCA, "             + CRLF
	cQuery += "     SLX.L4_VENDTEF                                      AS VEND_TEF, "             + CRLF
	cQuery += "     D2.D2_VALBRUT                                       AS VLR_TOTAL,"             + CRLF
	cQuery += "     D2.D2_VALICM                                        AS VLR_ICM,  "             + CRLF
	cQuery += "     D2.D2_VALIMP6                                       AS VLR_PIS,  "             + CRLF
	cQuery += "     D2.D2_VALIMP5                                       AS VLR_COF,  "             + CRLF
	cQuery += "     D2.D2_TES                                           AS TES,      "             + CRLF
	cQuery += "     D2.D2_TIPO                                          AS TIPO,     "             + CRLF
	cQuery += "     SF2.F2_CHVNFE                                       AS CHVNFE    "             + CRLF
	cQuery += " FROM " + RetSqlName("SD2") + " D2 "                                                + CRLF

	// Join SA1 para nome reduzido do cliente
	cQuery += " INNER JOIN " + RetSqlName("SA1") + " SA1 ON"                                        + CRLF
	cQuery += "    SA1.A1_COD        = D2.D2_CLIENTE "                                              + CRLF
	cQuery += "    AND SA1.A1_LOJA       = D2.D2_LOJA "                                             + CRLF
	cQuery += "    AND SA1.D_E_L_E_T_    = ' ' "                                                    + CRLF

	// SE1 via OUTER APPLY TOP 1 (evita duplicar: 1 NF gera N parcelas)
	// Filtros relaxados (FILIAL+NUM) + ORDER prefere TEF e mesmo cliente/loja
	cQuery += " OUTER APPLY ( SELECT TOP 1 ISNULL(E1.E1_TIPO,' ') AS E1_TIPO, ISNULL(E1.E1_NOMCLI,' ') AS E1_NOMCLI, " + CRLF
	cQuery += "    ISNULL(E1.E1_CARTAUT,' ') AS E1_CARTAUT, ISNULL(E1.E1_DOCTEF,' ') AS E1_DOCTEF, "                 + CRLF
	cQuery += "    ISNULL(E1.E1_NSUTEF,' ') AS E1_NSUTEF "                                                          + CRLF
	cQuery += "    FROM " + RetSqlName("SE1") + " E1 "                                                         + CRLF
	cQuery += "    WHERE E1.E1_FILIAL  = D2.D2_FILIAL "                                                        + CRLF
	cQuery += "    AND E1.E1_NUM       = D2.D2_DOC "                                                           + CRLF
	cQuery += "    AND E1.D_E_L_E_T_   = ' ' "                                                                 + CRLF
	cQuery += "    ORDER BY CASE WHEN E1.E1_CARTAUT <> ' ' OR E1.E1_NSUTEF <> ' ' OR E1.E1_DOCTEF <> ' ' "      + CRLF
	cQuery += "      THEN 0 ELSE 1 END, "                                                                      + CRLF
	cQuery += "      CASE WHEN E1.E1_CLIENTE = D2.D2_CLIENTE AND E1.E1_LOJA = D2.D2_LOJA THEN 0 ELSE 1 END, "   + CRLF
	cQuery += "      E1.E1_PARCELA ) SE1 "                                                                    + CRLF

	// Join SB1 para descricao do produto (assume SB1 NAO compartilhada entre filiais)
	cQuery += " INNER JOIN " + RetSqlName("SB1") + " SB1 ON"                                        + CRLF
	cQuery += "    SB1.B1_COD        = D2.D2_COD "                                                  + CRLF
	cQuery += "    AND SB1.D_E_L_E_T_    = ' ' "                                                    + CRLF

	// Join SF2 (por chave de cabecalho) apenas para trazer a Chave da NF-e
	cQuery += " LEFT JOIN " + RetSqlName("SF2") + " SF2 "                                          + CRLF
	cQuery += "    ON  SF2.F2_FILIAL     = D2.D2_FILIAL "                                          + CRLF
	cQuery += "    AND SF2.F2_DOC        = D2.D2_DOC "                                             + CRLF
	cQuery += "    AND SF2.F2_SERIE      = D2.D2_SERIE "                                           + CRLF
	cQuery += "    AND SF2.F2_CLIENTE    = D2.D2_CLIENTE "                                         + CRLF
	cQuery += "    AND SF2.F2_LOJA       = D2.D2_LOJA "                                            + CRLF
	cQuery += "    AND SF2.D_E_L_E_T_    = ' ' "                                                   + CRLF

	// SL2/SL4 via OUTER APPLY TOP 1 (evita duplicar: N formas TEF por orcamento)
	// Filtros relaxados (FILIAL+DOC+PRODUTO) + ORDER prefere mesma SERIE/EMISSAO
	cQuery += " OUTER APPLY ( SELECT TOP 1 ISNULL(L2.L2_NUM,' ') AS L2_NUM, ISNULL(L4.L4_VENDTEF,' ') AS L4_VENDTEF " + CRLF
	cQuery += "    FROM " + RetSqlName("SL2") + " L2 "                                             + CRLF
	cQuery += "    LEFT JOIN " + RetSqlName("SL4") + " L4 "                                        + CRLF
	cQuery += "    ON  L4.L4_FILIAL  = L2.L2_FILIAL "                                              + CRLF
	cQuery += "    AND L4.L4_NUM     = L2.L2_NUM "                                                 + CRLF
	cQuery += "    AND L4.D_E_L_E_T_ = ' ' "                                                       + CRLF
	cQuery += "    WHERE L2.L2_FILIAL  = D2.D2_FILIAL "                                            + CRLF
	cQuery += "    AND L2.L2_DOC       = D2.D2_DOC "                                               + CRLF
	cQuery += "    AND L2.L2_PRODUTO   = D2.D2_COD "                                               + CRLF
	cQuery += "    AND L2.D_E_L_E_T_   = ' ' "                                                     + CRLF
	cQuery += "    ORDER BY CASE WHEN L2.L2_SERIE = D2.D2_SERIE THEN 0 ELSE 1 END, "                + CRLF
	cQuery += "      CASE WHEN L2.L2_EMISSAO = D2.D2_EMISSAO THEN 0 ELSE 1 END ) SLX "              + CRLF

	cQuery += " WHERE D2.D2_FILIAL BETWEEN '" + cFilDe + "' AND '" + cFilAte + "' "                + CRLF
	cQuery += "   AND D2.D2_EMISSAO BETWEEN '" + DTOS(dDtDe) + "' AND '" + DTOS(dDtAte) + "' "     + CRLF
	cQuery += "  AND D2.D2_CF IN ('5102','5405') "                                                 + CRLF
	cQuery += "  AND D2.D_E_L_E_T_ = ' ' "                                                         + CRLF
	cQuery += " ORDER BY D2.D2_FILIAL, D2.D2_EMISSAO, D2.D2_DOC, D2.D2_SERIE, D2.D2_ITEM "

	cQuery := ChangeQuery(cQuery)

	TcQuery cQuery New Alias (cAlias)

	oSection01:Init()

	While (cAlias)->(!Eof())

		oReport:IncMeter()

		oSection01:Cell('FILIAL'  ):SetValue( (cAlias)->FILIAL   )
		oSection01:Cell('EMISSAO' ):SetValue( STOD((cAlias)->EMISSAO) )
		oSection01:Cell('NUM_ORCA'):SetValue( (cAlias)->NUM_ORCA)
		oSection01:Cell('NFDOC'   ):SetValue( (cAlias)->NF_DOC   )
		oSection01:Cell('SERIE'   ):SetValue( (cAlias)->NF_SERIE )
		oSection01:Cell('CFOP'    ):SetValue( (cAlias)->CFOP     )
		oSection01:Cell('CLIENTE' ):SetValue( (cAlias)->CLIENTE  )
		oSection01:Cell('LOJA'    ):SetValue( (cAlias)->LOJA     )
		oSection01:Cell('NOMECLI' ):SetValue( (cAlias)->NOME_CLI )
		oSection01:Cell('PRODUTO' ):SetValue( (cAlias)->PRODUTO  )
		oSection01:Cell('DESCPRD' ):SetValue( (cAlias)->DESC_PRD )
		oSection01:Cell('TES'     ):SetValue( (cAlias)->TES      )
		oSection01:Cell('TIPO'    ):SetValue( (cAlias)->TIPO     )
		If Alltrim((cAlias)->TIPO_PAG) == 'R$'
			oSection01:Cell('FORMPAG' ):SetValue( (cAlias)->TIPO_PAG+"- "+"DINHEIRO") 
		Else 
			oSection01:Cell('FORMPAG' ):SetValue( (cAlias)->TIPO_PAG+"- "+(cAlias)->NOME_PAG )
		Endif
		//Inclusao dos novos campos SE1
		oSection01:Cell('CARTAUT' ):SetValue( (cAlias)->CARTAUT)
		oSection01:Cell('DOCTEF'  ):SetValue( (cAlias)->DOCTEF)
		oSection01:Cell('NSUTEF'  ):SetValue( (cAlias)->NSUTEF)
		If Alltrim((cAlias)->VEND_TEF) == 'S' 
			oSection01:Cell('VEND_TEF'):SetValue( ("CARTAO"))
		Endif
		If Alltrim((cAlias)->VEND_TEF) <> 'S' 
			oSection01:Cell('VEND_TEF'):SetValue( ("POS"))
		Endif
		If Alltrim((cAlias)->TIPO_PAG) == 'R$'
			oSection01:Cell('VEND_TEF'):SetValue( ("R$"))
		Endif
		If Alltrim((cAlias)->TIPO_PAG) == 'PX'
			oSection01:Cell('VEND_TEF'):SetValue( ("PIX"))
		Endif
		oSection01:Cell('VLRTOTAL'):SetValue( (cAlias)->VLR_TOTAL)
		oSection01:Cell('VLRICM'  ):SetValue( (cAlias)->VLR_ICM  )
		oSection01:Cell('VLRPIS'  ):SetValue( (cAlias)->VLR_PIS  )
		oSection01:Cell('VLRCOF'  ):SetValue( (cAlias)->VLR_COF  )
		oSection01:Cell('CHVNFE'  ):SetValue( (cAlias)->CHVNFE   )

		oSection01:PrintLine()

		(cAlias)->(DbSkip())
	EndDo

	oSection01:Finish()

	(cAlias)->(DbCloseArea())

Return Nil

/*---------------------------------------------------------------------*
| Func:  AjustaSX1                                                    |
| Autor: Edmar Paranhos                                               |
| Data:  03/07/2026                                                   |
| Desc:  Cria as perguntas (SX1) do relatorio, se ainda nao existirem. |
*---------------------------------------------------------------------*/

Static Function AjustaSX1()

	Local aAlias := GetArea()
	Local aREGS  := {}
	Local I, J

	DBSelectArea("SX1")
	DBSetOrder(1)
	cPerg := Padr(cPerg, 10)

	aAdd(aRegs,{"RlFatLuna","01","Emissao De?" ,'','',"mv_ch1","D",08,0,0,"G","","mv_par01","","","mv_par01","","","","","","","","","","","","","","","",""})
	aAdd(aRegs,{"RlFatLuna","02","Emissao Ate?",'','',"mv_ch2","D",08,0,0,"G","","mv_par02","","","mv_par02","","","","","","","","","","","","","","","",""})
	aAdd(aRegs,{"RlFatLuna","03","Filial De?"  ,"","","mv_ch3","C",02,0,0,"G","","mv_par03","","","","","","","","","","","","","","","","","","","","","","","","","SM0","",""})
	aAdd(aRegs,{"RlFatLuna","04","Filial Ate?" ,"","","mv_ch4","C",02,0,0,"G","","mv_par04","","","","","","","","","","","","","","","","","","","","","","","","","SM0","",""})

	For I := 1 To Len(aREGS)

		// Localizou o registro - faz UPDATE para corrigir eventuais divergencias
		If DBSeek(cPerg + aREGS[I,2])
			RecLock("SX1", .F.)  // .F. = lock para edicao (UPDATE)
			For J := 1 To FCount()
				If J <= Len(aREGS[I])
					FieldPut(J, aREGS[I,J])
				EndIf
			Next
			MsUnlock()
		Else
			// Nao localizou - faz INSERT
			RecLock("SX1", .T.)  // .T. = novo registro (INSERT)
			For J := 1 To FCount()
				If J <= Len(aREGS[I])
					FieldPut(J, aREGS[I,J])
				EndIf
			Next
			MsUnlock()
		EndIf

	Next

	RestArea(aAlias)

Return Nil
