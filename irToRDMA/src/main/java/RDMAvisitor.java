// -*-  indent-tabs-mode:nil; c-basic-offset:4; -*-
import java.util.List;

import javax.management.RuntimeErrorException;

import java.util.ArrayList;

public class RDMAvisitor extends TLBaseVisitor<Object> {
    InstanceValue result;
    StringBuilder simpleExpressionBuffer, expressionBuffer;

    Node currentNode;
    Proc currentProc;
    int counter;

    public RDMAvisitor(InstanceValue result) {
        this.result = result;
        simpleExpressionBuffer = new StringBuilder();
        expressionBuffer = new StringBuilder();
    }

    @Override
    public Object visitNode(TLParser.NodeContext ctx) {
        int nodeNumber = Integer.parseInt(ctx.Number().getText());
        this.currentNode = new Node(nodeNumber);
        result.nodes.add(this.currentNode);
        result.processContents.put(this.currentNode.nodeNumber, new ArrayList<>());

        visitChildren(ctx);
        return null;
    }
    
    @Override
    public Object visitProcess(TLParser.ProcessContext ctx) {
        int procNumber = Integer.parseInt(ctx.Number().getText());
        this.currentProc = new Proc(procNumber);
        result.processes.add(this.currentProc);
        result.nodeProcesses.get(currentNode.nodeNumber).add(procNumber);
        result.processContents.put(this.currentProc.procNumber, new ArrayList<>());

        visitChildren(ctx);
        return null;
    }

    @Override
    public Object visitSharedDecl(TLParser.SharedDeclContext ctx) {
        return null;//handled by VarVisitor
    }

    @Override
    public Object visitLocalDecl(TLParser.LocalDeclContext ctx) {
        return null;//handled by VarVisitor
    }

//    @Override
//    public Object visitStatement(TLParser.StatementContext ctx) {
//        visitChildren(ctx);
//        return null;
//    }

    @Override
    public Object visitAssignment(TLParser.AssignmentContext ctx) {
        List<String> insts = result.processContents.get(this.currentProc.procNumber);

        String lhs = ctx.Identifier().getText();

        expressionBuffer.setLength(0);
        if (ctx.expression() instanceof TLParser.NumberExpressionContext)
            visitNumberExpression((TLParser.NumberExpressionContext)ctx.expression());
        else {
            System.out.println("unhandled expr in assignment stmt");
            System.exit(1);
        }

        String rhs = expressionBuffer.toString();

        String newInst = String.format("%s = %s;", lhs, rhs);
        insts.add(newInst);

        return null;
    }

    @Override
    public Object visitPollcq(TLParser.PollcqContext ctx) {
        List<String> insts = result.processContents.get(this.currentProc.procNumber);
        insts.add("send_flush(peer, cq, conn, true);");
        //TODO: fix code
        throw new RuntimeException("not implemented yet");
        //.visitChildren(ctx);
        //return null;
    }

    @Override
    public Object visitStore(TLParser.StoreContext ctx) {
        List<String> insts = result.processContents.get(this.currentProc.procNumber);

        String writeVar = ctx.Identifier().getText();
        String rhs = ctx.rhs().getText();

        String newInst = String.format("*%s = %s;", writeVar, rhs);
        insts.add(newInst);

        return null;
    }

    @Override
    public Object visitLoad(TLParser.LoadContext ctx) {
        List<String> insts = result.processContents.get(this.currentProc.procNumber);

        String lhs = ctx.Identifier(0).getText();
        String readVar = ctx.Identifier(1).getText();

        String newInst = String.format("%s = *%s;", lhs, readVar);
        insts.add(newInst);
        throw new RuntimeException("not implemented yet");

        //return null;
    }

    @Override
    public Object visitGet(TLParser.GetContext ctx) {
        List<String> insts = result.processContents.get(this.currentProc.procNumber);

        int destProcessNumber = Integer.parseInt(ctx.Number().getText());
        String writeVar = ctx.Identifier(0).getText();
        String readVar = ctx.Identifier(1).getText();
        String readName = "vr" + counter;
        String writeName = "vw" + counter;


        String newInst = String.format
	    ("rdma_operation(app, conn, *conn->peer_mr, %s - vars, %s, conn->rdma_mr, IBV_WR_RDMA_READ, 0);", readVar, writeVar);
        insts.add(newInst);

	Integer c;
	if (result.processRemoteOpCounts.containsKey(this.currentProc.procNumber)) {
	    c = result.processRemoteOpCounts.get(this.currentProc.procNumber);
	} else {
	    c = new Integer(0);
	}
	c = c + 1;
	result.processRemoteOpCounts.put(this.currentProc.procNumber, c);

        return null;
    }

    @Override
    public Object visitPut(TLParser.PutContext ctx) {
        List<String> insts = result.processContents.get(this.currentProc.procNumber);

        int destProcessNumber = Integer.parseInt(ctx.Number().getText());
        String writeVar = ctx.Identifier(0).getText();
        String readVar = ctx.Identifier(1).getText();
        String readName = "vr" + counter;
        String writeName = "vw" + counter;


        String newInst = String.format
                ("rdma_operation(app, conn, *conn->peer_mr, %s - vars, %s, conn->rdma_mr, IBV_WR_RDMA_WRITE, 0);", writeVar, readVar);
        insts.add(newInst);
        throw new RuntimeException("not implemented yet");

        //return null;
    }

    @Override
    public Object visitCas(TLParser.CasContext ctx) {
        List<String> insts = result.processContents.get(this.currentProc.procNumber);

        int destProcessNumber = Integer.parseInt(ctx.Number(0).getText());
        String writeVar = ctx.Identifier(0).getText();
        String rwVar = ctx.Identifier(1).getText();
        String r1Var = ctx.Identifier(2).getText();
        String r2Var = ctx.Identifier(3).getText();

        String newInst = String.format
            ("rdma_operation_cas(app, conn, *conn->peer_mr, %s - vars, %s, conn->rdma_mr, *%s, *%s);", rwVar, writeVar, r1Var, r2Var);
        insts.add(newInst);

        return null;
    }

    @Override
    public Object visitOutput(TLParser.OutputContext ctx) {
        simpleExpressionBuffer.setLength(0);

        visitSimpleExpression(ctx.simpleExpression());

        result.outputs.add(simpleExpressionBuffer.toString());
        return null;
    }

    @Override
    public Object visitRga(TLParser.RgaContext ctx) {
        // W = rga(RW, R)
        List<String> insts = result.processContents.get(this.currentProc.procNumber);

        int destProcessNumber = Integer.parseInt(ctx.Number(0).getText());
        String writeVar = ctx.Identifier(0).getText();
	String rwVar = ctx.Identifier(1).getText();
        String readVar = ctx.Identifier(2).getText();
        String writeName = "vw" + counter;
        String rwName = "vrw" + counter;
        String readName = "vr" + counter;


        String newInst = String.format
            ("rdma_operation_rga(app, conn, *conn->peer_mr, %s - vars, %s, conn->rdma_mr, *%s);", rwVar, writeVar, readVar);
        insts.add(newInst);
        throw new RuntimeException("not implemented yet");

        //return null;
    }
 
    @Override
    public Object visitRhs(TLParser.RhsContext ctx) {
        simpleExpressionBuffer.append(ctx.getText());
        return null;
    }

    @Override
    public Object visitNumberExpression(TLParser.NumberExpressionContext ctx) {
	expressionBuffer.append(ctx.Number());
	return null;
    }

    @Override
    public Object visitSimpleExpression(TLParser.SimpleExpressionContext ctx) {
        if (ctx.And() != null) {
            /* simpleExpression And simpleExpression*/
            simpleExpressionBuffer.append("(");
            visitSimpleExpression(ctx.simpleExpression(0));
            simpleExpressionBuffer.append(" && ");
            visitSimpleExpression(ctx.simpleExpression(1));
            simpleExpressionBuffer.append(")");

        } else if (ctx.Or() != null) {
            /* simpleExpression Or simpleExpression */
            simpleExpressionBuffer.append("(");
            visitSimpleExpression(ctx.simpleExpression(0));
            simpleExpressionBuffer.append(" || ");
            visitSimpleExpression(ctx.simpleExpression(1));
            simpleExpressionBuffer.append(")");

        } else if (ctx.Excl() != null) {
            /* Excl simpleExpression */
            simpleExpressionBuffer.append("! (");
            visitSimpleExpression(ctx.simpleExpression(0));
            simpleExpressionBuffer.append(")");

        } else if (ctx.OParen() != null) {
            /* OParen simpleExpression CParen */
            simpleExpressionBuffer.append("(");
            visitSimpleExpression(ctx.simpleExpression(0));
            simpleExpressionBuffer.append(")");

        }else if (ctx.Equals() != null) {
            /* Identifier Equals rhs */
            simpleExpressionBuffer.append(ctx.Identifier().getText() + " == " );
            visitRhs(ctx.rhs());

        } else if (ctx.NEquals() != null) {
            /* Identifier NEquals rhs */
            simpleExpressionBuffer.append("(" + ctx.Identifier().getText() + " != " );
            visitRhs(ctx.rhs());
            simpleExpressionBuffer.append(")");

        } else {
            System.err.println("Error");
            System.exit(1);
        }
        return null;
    }

    @Override
    public Object visitAssumption(TLParser.AssumptionContext ctx) {
        /* Reset the buffer */
        simpleExpressionBuffer.setLength(0);

        visitSimpleExpression(ctx.simpleExpression());

        // System.out.println("Assumption found: " + simpleExpressionBuffer.toString());

        return null;
    }

    @Override
    public Object visitAssertion(TLParser.AssertionContext ctx) {
        /* Reset the buffer */
        simpleExpressionBuffer.setLength(0);

        visitSimpleExpression(ctx.simpleExpression());

        /* Append buffer to result */
        result.owningProcess.put(ctx.simpleExpression(), currentProc.procNumber);
        result.assertions.add(ctx.simpleExpression());

        // System.out.println("Assertion found: " + result.Assertion.toString());

        return null;
    }

    @Override
    public Object visitIfStatement(TLParser.IfStatementContext ctx) {
        simpleExpressionBuffer.setLength(0);

        visitSimpleExpression(ctx.simpleExpression());

        return null;
    }
}
