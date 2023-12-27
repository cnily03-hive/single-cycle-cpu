const WARN_PREFIX = '\x1b[33mWarning:\x1b[0m'
const ERROR_PREFIX = '\x1b[31mError:\x1b[0m'

class ConsoleIO {
    error(...args) { console.error(ERROR_PREFIX, ...args); return this }
    warn(...args) { console.warn(WARN_PREFIX, ...args); return this }
    info(...args) { // blue
        console.info(`\x1b[34m${args.map(v => Object.prototype.valueOf.call(v)).join(' ')}\x1b[0m`);
        return this
    }
    success(...args) { // green
        console.log(`\x1b[32m${args.map(v => Object.prototype.valueOf.call(v)).join(' ')}\x1b[0m`);
        return this
    }
    tip(...args) { // cyan
        console.log(`\x1b[36m${args.map(v => Object.prototype.valueOf.call(v)).join(' ')}\x1b[0m`);
        return this
    }
    note(...args) { // magenta
        console.log(`\x1b[35m${args.map(v => Object.prototype.valueOf.call(v)).join(' ')}\x1b[0m`);
        return this
    }
    log(...args) { console.log(...args); return this }
    exit(...args) { process.exit(...args) }
}

const io = new ConsoleIO()

const fs = require('fs')
const path = require('path')



let filepath, top_opts = {
    bin: true,
    hex: true,
    comment: false,
    strict: false,
    basename: false, // same as file basename
}, alias_map = {
    b: "bin",
    h: "hex",
    c: "comment",
    s: "strict",
    o: "basename",
}



// Prase arguments

let on_opt_pending = false, pending_opt_name = null
process.argv.slice(2).forEach(function (val, index, array) {
    let format_val = val.trim()

    // Transform alias
    if (/^--[a-zA-Z\-]+$/.test(format_val)) format_val = format_val.toLowerCase()
    else if (/^-[a-zA-Z]+$/.test(format_val)) {
        let short_opt_name = format_val.slice(1)
        if (!Object.keys(alias_map).includes(short_opt_name)) {
            io.error(`No such option: ${short_opt_name}`).exit(1)
        }
        format_val = `--${alias_map[short_opt_name]}`
    }

    // Parse arguments
    if (/^--[a-zA-Z\-]+$/.test(format_val)) { // option key
        let opt_name = format_val.slice(2)
        if (opt_name === "bin") {
            if (top_opts["hex"] && top_opts["bin"]) top_opts["hex"] = false
            top_opts[opt_name] = true
        } else if (opt_name === "hex") {
            if (top_opts["hex"] && top_opts["bin"]) top_opts["bin"] = false
            top_opts[opt_name] = true
        } else if (opt_name === "comment") {
            top_opts[opt_name] = true
        } else if (opt_name === "strict") {
            top_opts[opt_name] = true
        } else if (Object.keys(top_opts).includes(opt_name)) { // option value
            pending_opt_name = opt_name
            on_opt_pending = true
        } else {
            io.error(`No such option: ${opt_name}`).exit(1)
        }
    } else if (on_opt_pending) { // option value
        top_opts[pending_opt_name] = format_val
        on_opt_pending = false
        pending_opt_name = null
    } else { // filepath
        filepath = format_val
    }
})



// Check arguments

if (!filepath) {
    io.error('Please provide a file path').exit(1)
}

let abs_filepath = path.resolve(process.cwd(), filepath)

if (fs.existsSync(abs_filepath) === false) {
    io.error('File not found: ' + filepath).exit(1)
}

if (fs.statSync(abs_filepath).isDirectory()) {
    io.error(`'${filepath}' is a directory`).exit(1)
}

const file_dir = path.dirname(abs_filepath)
const output_basename = (typeof top_opts.basename === "string" && top_opts.basename) ?
    top_opts.basename
    : path.basename(abs_filepath, path.extname(abs_filepath))

const asm_content = fs.readFileSync(abs_filepath, 'utf8')


// Transformer function

/**
 * Transform asm lines to binary lines
 * @param {Array} input_asm_lines asm lines array
 * @param {Object} options
 * @param {boolean} options.warn enable warning
 * @param {boolean} options.comment enable comment
 * @returns {Array} binary lines array
 */
function asm2bin(input_asm_lines, options = {
    warn: true,
    comment: true,
}) {
    const opts = {
        warn: typeof options.warn === 'undefined' ? true : options.warn,
        comment: typeof options.comment === 'undefined' ? true : options.comment,
    }
    const ENABLE_WARN = opts.warn
    const ENABLE_COMMENT = opts.comment

    let CurFileLine = 0;
    let CurPC = 0;

    // Environment declaration
    const VALID_ASM_OP_OBJ = {
        R: {
            ADD: 'add',
            ADDU: 'addu',
            SUB: 'sub',
            SUBU: 'subu',
            AND: 'and',
            OR: 'or',
            XOR: 'xor',
            SLL: 'sll',
            SRL: 'srl',
            SRA: 'sra',
        },
        I: {
            ADDI: 'addi',
            ADDIU: 'addiu',
            ANDI: 'andi',
            ORI: 'ori',
            LW: 'lw',
            SW: 'sw',
            BEQ: 'beq',
            BNE: 'bne',
        },
        J: {
            J: 'j',
        },
    }

    const VALID_ASM_OP_ARR = Object.values(VALID_ASM_OP_OBJ).map(o => Object.values(o)).flat()

    let NUMBER_REG_MAP = [] // [$0, $1, $2, ...] in asm
    let REG_MAP = {} // { $zero: $0, $s0: $1, ... } assigned

    /**
     * Get register address string
     * @param {string} str format like `$0`, `$zero`, `$s0`, etc
     * @returns {string} 5-bit binary string
     */
    const getRegAddr = str => {
        let regpos
        if (/^\$[a-z0-9]+$/i.test(str)) {
            const param = str.slice(1).toLowerCase()
            if (REG_MAP[param]) regpos = REG_MAP[param]
            else if (param === 'zero' && !NUMBER_REG_MAP.includes(0)) regpos = REG_MAP['zero'] = 0
            else if (/^\d+$/.test(param)) regpos /* = REG_MAP[param] */ = parseInt(param, 10)
            else {
                // Auto Assign
                let arr_copy = [...new Set([...NUMBER_REG_MAP, ...Object.values(REG_MAP)].flat())].sort((a, b) => a - b)
                let i = 1 // reserve $0
                while (arr_copy.length && arr_copy[0] < i) arr_copy.shift()
                while (arr_copy.length && i === arr_copy[0]) {
                    arr_copy.shift()
                    ++i
                }
                regpos = REG_MAP[param] = i
                io.info(`Assigned \$${i} to \$${param}`)
            }
            if (regpos > (1 << 5) - 1) {
                if (ENABLE_WARN) io.warn(`Line ${CurFileLine}: Register ${str}${String(regpos) === param ? '' : ` (assigned \$${regpos})`} is too large!`)
                else io.error(`Line ${CurFileLine}: Register ${str} is too large`).exit(1)
            }
            return getBinStr(regpos, 5)
        } else io.error(`Line ${CurFileLine}: Invalid register: ${str}`).exit(1)
    }

    /**
     * Join 32-bit binary string with components
     * @param {Object} component
     * @param {string} component.opcode
     * @param {string} component.rs
     * @param {string} component.rt
     * @param {string} component.rd
     * @param {string} component.shamt
     * @param {string} component.funct
     * @param {string} component.imm
     * @param {string} component.addr
     * @returns {string} 32-bit binary string
     */
    const joinBit32 = ({ opcode, rs, rt, rd, shamt, funct, imm, addr }) => {
        const isValid = t => typeof t !== 'undefined' && t !== null
        let res = '';
        if (isValid(opcode) && isValid(rs) && isValid(rt) && isValid(rd) && isValid(shamt) && isValid(funct))
            res = `${opcode}${rs}${rt}${rd}${shamt}${funct}`
        else if (isValid(opcode) && isValid(rs) && isValid(rt) && isValid(imm))
            res = `${opcode}${rs}${rt}${imm}`
        else if (isValid(opcode) && isValid(addr))
            res = `${opcode}${addr}`

        if (res.length !== 32) io.error(`Line ${CurFileLine}: Invalid bit32 length: ${res}`).exit(1)
        return res
    }

    /**
     * Parse asm number string to number
     * @param {string} asm_num_string format like 0x1234, #8, -9, 16, etc
     * @returns {number} number
     */
    const parseAsmNum = (asm_num_string) => {
        str = asm_num_string.trim().toLowerCase()
        if (/^#-?\d+$/i.test(str)) return parseInt(str.slice(1), 10)

        let neg = /^-/i.test(str) ? -1 : 1

        if (/^0x[0-9a-fA-F]+$/.test(str)) return parseInt(str.slice(2), 16) * neg
        if (/^0b[01]+$/.test(str)) return parseInt(str.slice(2), 2) * neg
        if (/^0[0-7]+$/.test(str)) return parseInt(str.slice(1), 8) * neg

        if (/^0x[0-9a-fA-F]+[Hh]$/.test(str)) return parseInt(str.slice(2, -1), 16) * neg
        if (/^0b[01]+[Bb]$/.test(str)) return parseInt(str.slice(2, -1), 2) * neg

        if (/^[0-9a-f]+H$/i.test(str)) return parseInt(str.slice(0, -1), 16) * neg
        if (/^[01]+B$/i.test(str)) return parseInt(str.slice(0, -1), 2) * neg
        if (/^[0-7]+[OQ]$/i.test(str)) return parseInt(str.slice(0, -1), 8) * neg
        if (/^\d+D$/i.test(str)) return parseInt(str.slice(0, -1), 10) * neg

        if (/^\d+$/i.test(str)) return parseInt(str, 10) * neg

        io.error(`Line ${CurFileLine}: Invalid number format: ${asm_num_string}`).exit(1)
    }

    const getBinStr = (strOrNum, width, warn = ENABLE_WARN) => {
        let num = typeof strOrNum === 'string' ? parseAsmNum(strOrNum) : strOrNum
        if (num < 0) num = (((1 << width) - 1) ^ (-num)) + 1
        let res = num.toString(2)
        if (res.length > width) {
            if (warn) io.warn(`Line ${CurFileLine}: Number ${str} is too large, will be truncated`)
            else io.error(`Line ${CurFileLine}: Number ${str} is too large`).exit(1)
        }
        return res.padStart(width, '0')
    }

    // Asm Handler Generator
    const _gen = {
        RType_rs_rt_rd(funct) {
            return function (op1, op2, op3) {
                return joinBit32({
                    opcode: '000000',
                    rs: getRegAddr(op2),
                    rt: getRegAddr(op3),
                    rd: getRegAddr(op1),
                    shamt: '00000',
                    funct: funct,
                })
            }
        },
        RType_rt_rd_shmat(funct) {
            return function (op1, op2, op3) {
                return joinBit32({
                    opcode: '000000',
                    rs: '00000',
                    rt: getRegAddr(op2),
                    rd: getRegAddr(op1),
                    shamt: getBinStr(op3, 5),
                    funct: funct,
                })
            }
        },
        IType_rs_rt_imm(opcode) {
            return function (op1, op2, op3) {
                return joinBit32({
                    opcode: opcode,
                    rs: getRegAddr(op2),
                    rt: getRegAddr(op1),
                    imm: getBinStr(op3, 16),
                })
            }
        },
        IType_lw_sw(opcode) {
            return function (op1, op2) {
                let regexpres = /^(.+)\((.+)\)$/.exec(op2)
                if (!regexpres) io.error(`Line ${CurFileLine}: Invalid format: ${op2}`).exit(1)
                const offset = regexpres[1], base = regexpres[2]
                return joinBit32({
                    opcode: opcode,
                    rs: getRegAddr(base),
                    rt: getRegAddr(op1),
                    imm: getBinStr(offset, 16),
                })
            }
        },
        IType_beq_bne(opcode) {
            return function (op1, op2, op3) {
                let offset
                // offset
                if (/^(\-|#)/.test(op3) || /^\d+$/.test(op3)) offset = parseAsmNum(op3)
                // absolute address
                else if (/^0x[0-9a-fA-F]+$/.test(op3) ||
                    /^0b[01]+$/.test(op3) ||
                    /^[0-9a-f]+H$/i.test(op3) ||
                    /^[01]+B$/i.test(op3) ||
                    /^[0-7]+[OQ]$/i.test(op3) ||
                    /^\d+D$/i.test(op3)) {
                    offset = (parseAsmNum(op3) - CurPC - 4) >> 2
                }
                // label
                else if (/^[a-zA-Z_][a-zA-Z_\(\)\d]*$/i.test(op3)) {
                    if (!jump_table[op3]) io.error(`Line ${CurFileLine}: Label ${op3} not found`).exit(1)
                    offset = (jump_table[op3] - CurPC - 4) >> 2
                }
                // label with offset (label+offset or label-offset)
                else if (/^[a-zA-Z_][a-zA-Z_\(\)\d]*([+\-])\d+$/i.test(op3)) {
                    let spliter = /^[a-zA-Z_][a-zA-Z_\(\)\d]*([+\-])\d+$/i.exec(op3)[1]
                    const [_label, _offset] = op3.split(/[+\-]/)
                    let _offset_num = spliter === '+' ? parseAsmNum(_offset) : - parseAsmNum(_offset)

                    if (!jump_table[_label]) io.error(`Line ${CurFileLine}: Label ${_label} not found`).exit(1)
                    if ((jump_table[_label] >> 2) + _offset_num < 0) {
                        if (ENABLE_WARN) io.warn(`Line ${CurFileLine}: Address may be negative for ${op3}`)
                        else io.error(`Line ${CurFileLine}: Address may be negative for ${op3}`).exit(1)
                    }

                    offset = ((jump_table[op3] - CurPC - 4) >> 2) + _offset_num
                }
                // Exception
                else io.error(`Line ${CurFileLine}: Invalid format: ${op3}`).exit(1)
                return joinBit32({
                    opcode: opcode,
                    rs: getRegAddr(op1),
                    rt: getRegAddr(op2),
                    imm: getBinStr(offset, 16),
                })
            }
        },
        JType(opcode) {
            return function (op1) {
                let addr
                // label
                if (/^[a-zA-Z_][a-zA-Z_\(\)\d]*$/i.test(op1)) {
                    if (!jump_table[op1]) io.error(`Line ${CurFileLine}: Label ${op1} not found`).exit(1)
                    addr = jump_table[op1] >> 2
                }
                // label with offset (label+offset or label-offset)
                else if (/^[a-zA-Z_][a-zA-Z_\(\)\d]*([+\-])\d+$/i.test(op1)) {
                    let spliter = /^[a-zA-Z_][a-zA-Z_\(\)\d]*([+\-])\d+$/i.exec(op1)[1]
                    const [_label, _offset] = [op1.slice(0, op1.indexOf(spliter)), op1.slice(op1.indexOf(spliter) + 1)]
                    let _offset_num = spliter === '+' ? parseAsmNum(_offset) : - parseAsmNum(_offset)

                    if (!jump_table[_label]) io.error(`Line ${CurFileLine}: Label ${_label} not found`).exit(1)
                    if ((jump_table[_label] >> 2) + _offset_num < 0) {
                        if (ENABLE_WARN) io.warn(`Line ${CurFileLine}: Address may be negative for ${op1}`)
                        else io.error(`Line ${CurFileLine}: Address may be negative for ${op1}`).exit(1)
                    }

                    addr = (jump_table[_label] >> 2) + _offset_num
                }
                // Exception
                else {
                    try {
                        addr = parseAsmNum(op1) >> 2
                    } catch (e) {
                        io.error(`Line ${CurFileLine}: Invalid format: ${op1}`).exit(1)
                    }
                }

                return joinBit32({
                    opcode: opcode,
                    addr: getBinStr(addr, 26),
                })
            }
        },
    }
    // Asm Handler
    const AsmHandler = {
        _gen,
        // R Type
        add: _gen.RType_rs_rt_rd('100000'),
        addu: _gen.RType_rs_rt_rd('100001'),
        sub: _gen.RType_rs_rt_rd('100010'),
        subu: _gen.RType_rs_rt_rd('100011'),
        and: _gen.RType_rs_rt_rd('100100'),
        or: _gen.RType_rs_rt_rd('100101'),
        xor: _gen.RType_rs_rt_rd('100110'),
        nor: _gen.RType_rs_rt_rd('100111'),
        slt: _gen.RType_rs_rt_rd('101010'),
        sltu: _gen.RType_rs_rt_rd('101011'),
        sll: _gen.RType_rt_rd_shmat('000000'),
        srl: _gen.RType_rt_rd_shmat('000010'),
        sra: _gen.RType_rt_rd_shmat('000011'),
        sllv: _gen.RType_rs_rt_rd('000100'),
        srlv: _gen.RType_rs_rt_rd('000110'),
        srav: _gen.RType_rs_rt_rd('000111'),
        jr(op1) {
            return joinBit32({
                opcode: '000000',
                rs: getRegAddr(op1),
                rt: '00000',
                rd: '00000',
                shamt: '00000',
                funct: '001000',
            })
        },
        // I Type
        addi: _gen.IType_rs_rt_imm('001000'),
        addiu: _gen.IType_rs_rt_imm('001001'),
        andi: _gen.IType_rs_rt_imm('001100'),
        ori: _gen.IType_rs_rt_imm('001101'),
        xori: _gen.IType_rs_rt_imm('001110'),
        lui(op1, op2) {
            return joinBit32({
                opcode: '001111',
                rs: '00000',
                rt: getRegAddr(op1),
                imm: getBinStr(op2, 16),
            })
        },
        lw: _gen.IType_lw_sw('100011'),
        sw: _gen.IType_lw_sw('101011'),
        beq: _gen.IType_beq_bne('000100'),
        bne: _gen.IType_beq_bne('000101'),
        slti: _gen.IType_rs_rt_imm('001010'),
        sltiu: _gen.IType_rs_rt_imm('001011'),
        // J Type
        j: _gen.JType('000010'),
        jal: _gen.JType('000011'),
    }

    /**
     * Format a single line of asm code
     * @param {string} line a single line of asm code (this will reserve string like "LABEL:" and "LABEL: INST")
     * @returns {string} formatted line
     */
    const formatInst = (line) =>
        line.replace(/(#|;|\/\/).*/g, '') // remove comments
            .replace(/[,]/g, ' ') // replace comma with space
            .replace(/\( +/g, ' (') // remove extra spaces for left parentheses
            .replace(/ +\)/g, ') ') // remove extra spaces for right parentheses
            .replace(/ +/g, ' ').trim() // remove extra spaces

    let asm_lines = [], jump_table = {}, bin_lines = [];

    // Get asm_lines

    let tmpPC = 0, tmpLines = [...input_asm_lines]
    let PC2LINE_MAP = {} // { PC: Line Number}

    for (let i = 0; i < tmpLines.length; i++) {
        PC2LINE_MAP[tmpPC] = i + 1
        let fmtLine = formatInst(tmpLines[i])
        if (fmtLine.length === 0) continue

        if (/^[a-zA-Z_][a-zA-Z_\(\)\d]*:/i.test(fmtLine)) {
            const [label, inst] = fmtLine.split(':')
            jump_table[label] = tmpPC
            if (inst.trim().length == 0) continue // LABEL:
            else fmtLine = inst.trim() // LABEL: INST
        }

        // Examine if the label is invalid
        if (fmtLine.includes(':')) {
            io.error(`Line ${i + 1}: Invalid label ${fmtLine}`).exit(1)
        }

        // INST
        asm_lines.push({
            pc: tmpPC,
            asm_inst_str: fmtLine,
            asm_inst_arr: fmtLine.split(' ').map(s => s.trim())
        })

        // Scan register format \$\d+
        if (/\$(\d+)/i.test(fmtLine)) {
            const param = fmtLine.match(/\$(\d+)/i)[1]
            NUMBER_REG_MAP.push(parseInt(param, 10))
        }

        tmpPC += 4
    }

    NUMBER_REG_MAP = [...new Set(NUMBER_REG_MAP)].sort((a, b) => a - b)

    // Analyze asm_lines

    for (let i = 0; i < asm_lines.length; i++) {
        const asm_obj = asm_lines[i]
        const pc = asm_obj.pc
        CurFileLine = PC2LINE_MAP[pc]
        CurPC = pc
        const asmOp = asm_obj.asm_inst_arr[0].toLowerCase()

        if (!VALID_ASM_OP_ARR.includes(asmOp)) {
            io.error(`Line ${CurFileLine}: Invalid opcode: ${asmOp}`).exit(1)
        }

        if (typeof AsmHandler[asmOp] === "function") {
            bin_lines.push({
                pc: pc,
                bin_inst: AsmHandler[asmOp](...asm_obj.asm_inst_arr.slice(1))
            })
        }
    }

    // Output

    let head_comment = (() => {
        let max_num_len = Object.values(REG_MAP).reduce((a, b) => Math.max(a, b), 1).toString().length
        let max_var_len = Object.keys(REG_MAP).map(t => t.toString().length).reduce((a, b) => Math.max(a, b), 1)
        let num2varMap = {}
        let res = []
        for (let key in REG_MAP) num2varMap[REG_MAP[key]] = key
        const numValues = Object.keys(num2varMap)
        numValues.sort((a, b) => a - b)

        for (let key in num2varMap) {
            let num = key, varname = num2varMap[key]
            res.push(`\$${num.toString().padEnd(max_num_len, ' ')} : \$${varname.padEnd(max_var_len, ' ')}`)
        }
        i = 0;
        for (let key in REG_MAP) {
            let num = REG_MAP[key], varname = key
            res[i] += "   |   "
            res[i] += `\$${varname.padEnd(max_var_len, ' ')} : \$${num.toString().padEnd(max_num_len, ' ')}`
            ++i
        }
        return res.map(t => "# " + t.trim()).join('\n') || undefined
    })()

    // return content array

    if (ENABLE_COMMENT) return [...head_comment.filter(t => typeof t !== "undefined"), ...bin_lines.map(l => l.bin_inst)]
    else return bin_lines.map(l => l.bin_inst)
}

/**
 * Transform binary lines to hexified binary lines
 * @param {Array} input_bin_lines binary lines
 * @returns {Array} hexified binary lines
 */
function bin2hex(input_bin_lines) {
    return input_bin_lines.map(t => t
        .replace(/(#|\/\/).*?$/g, '') // remove comments
        .replace(/ /g, '') // remove spaces
        .trim() // trim lines
    ).filter(RegExp.prototype.test.bind(/^[01]+$/)) // filter invalid lines
        .map(t => Number("0b" + t).toString(16).toUpperCase().padStart(8, "0"))
}



// Main

let asm_lines = [], bin_lines = [], hex_lines = []

asm_lines = asm_content.split(/\r?\n/)
bin_lines = asm2bin(asm_lines, {
    warn: top_opts.strict ? false : true,
    comment: top_opts.comment,
})
if (top_opts.hex) hex_lines = bin2hex(bin_lines)



// Output

if (top_opts.bin) {
    let fp = path.resolve(file_dir, `${output_basename}.bin`)
    let content = bin_lines.join('\n')
    fs.writeFileSync(fp, content, 'utf8')
    io.success(`File created at '${fp}'`)
}

if (top_opts.hex) {
    let fp = path.resolve(file_dir, `${output_basename}.hex`)
    let content = hex_lines.join('\n')
    fs.writeFileSync(fp, content, 'utf8')
    io.success(`File created at '${fp}'`)
}
