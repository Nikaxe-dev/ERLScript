import { runTime } from "./main";

class token {

}

class lexer {
    public runTime: runTime
    public text: string = ""
    public position = 0
    public tokens: token[] = []
    public character: string = ""

    public addToken(token: token) {
        this.tokens.push(token)
    }

    public advance() {
        if (this.position == this.text.length) {
            this.character = null
            return
        }

        this.position += 1
        this.character = this.character.charAt(this.position)

        return this.character
    }
}

export {token,lexer}