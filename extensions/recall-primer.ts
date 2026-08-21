/**
 * recall-primer — 自动联想扩展（pi 专用）
 *
 * 在 before_agent_start 钩子里，用纯本地脚本 bin/recall 对用户输入做
 * BM25 匹配，把命中的文件标题+摘要注入本轮上下文。
 *
 * 关键设计：
 *   1. 零 token 成本 —— BM25 在 Python 里完成（~80ms），不调用任何模型
 *   2. 注入【标题+摘要】而非【文件路径】—— 模型已获得上下文，只有需要细节时才 read
 *   3. 命中 0 条则完全不注入 —— 宁可少提醒，不可污染上下文
 *   4. 硬上限 300 字符 —— 防止自己变成噪音源
 *   5. display: false —— 不在界面上刷屏，只给模型看
 */

import { execFile } from "node:child_process";
import * as os from "node:os";
import * as path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const RECALL = path.join(os.homedir(), ".pi", "agent", "bin", "recall");
const MAX_CHARS = 300;
const TIMEOUT_MS = 1500;

// 与 SKILL.md 触发规则对齐：打招呼 / 短回应 / 纯闲聊不值得联想
const SKIP_RE =
	/^(你好|您好|hi|hello|hey|嗨|在吗|早|晚上好|ok|okay|好|好的|嗯|嗯嗯|哦|收到|谢谢|多谢|thanks|thank you|不客气|继续|go on|next|辛苦了|晚安)[!！。.~～\s]*$/i;

function runRecall(text: string): Promise<string> {
	return new Promise((resolve) => {
		execFile(
			RECALL,
			["q", text.slice(0, 2000)],
			{ timeout: TIMEOUT_MS, encoding: "utf8" },
			(err, stdout) => {
				resolve(err ? "" : (stdout || "").trim());
			},
		);
	});
}

export default function activate(pi: ExtensionAPI) {
	pi.on("before_agent_start", async (event) => {
		const prompt = (event.prompt || "").trim();
		if (prompt.length < 4 || SKIP_RE.test(prompt)) return;

		const hit = await runRecall(prompt);
		if (!hit) return;

		return {
			message: {
				customType: "recall-primer",
				content:
					hit.slice(0, MAX_CHARS) +
					"\n（以上为浅层联想提示。规则：\n" +
					"1. 禁止直接 read 整篇文件！先用 grep -n 关键词 定向搜索确认相关段落\n" +
					"2. 只在命中 ≥2 个关键词时才读取\n" +
					"3. 只读取命中行附近 ±5 行，不读全文\n" +
					"4. 不相关直接忽略，不要强行关联）",
				display: false,
			},
		};
	});
}
